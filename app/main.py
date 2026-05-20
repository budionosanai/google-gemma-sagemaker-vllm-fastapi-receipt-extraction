from fastapi import FastAPI, UploadFile, File, HTTPException
from pydantic import BaseModel
import boto3
import json
import base64
import os

# FastAPI
app = FastAPI()

# Initialize SageMaker Runtime and SageMaker Endpoint
runtime_client = boto3.client("sagemaker-runtime")
endpoint_name = "gemma-4-receipt-extraction-vllm"

# Prompt Engineering
prompt = """
You are a receipt extraction assistant.

Write from this receipt then must careful, do not fabricate and return JSON with this fields:
- storeName: in UPPERCASE format only.
- purchaseDate: in DD-MM-YYYY format only. If month not number (word), convert to number. Example : 10/12/2023 to 10/12/2023 NOT 12/10/2023 .
- total: total amount as float only, no currency symbol, no comma.

Do NOT add explanation or markdown.
"""


# Receipt Extraction Schema Structured-Output
class receiptExtraction(BaseModel):
    storeName: str
    purchaseDate: str
    total: float


# Encode Image/Photo
def encode_image(image_bytes: bytes, filename: str):
    base64_image = base64.b64encode(image_bytes).decode('utf-8')
    ext = os.path.splitext(filename)[1].lower()
    mime_types = {
        '.jpg':  'image/jpeg',
        '.jpeg': 'image/jpeg',
        '.png':  'image/png'
    }
    mime_type = mime_types.get(ext, mime_types)
    return base64_image, mime_type


# Predict using SageMaker Endpoint Gemma 4 on vLLM
@app.post("/predict")
async def predict(file: UploadFile = File(...)):
    if file.content_type not in ["image/jpeg", "image/png"]:
        raise HTTPException(status_code=400, detail="Format must JPG or PNG")
    image_bytes = await file.read()
    base64_image, mime_type = encode_image(image_bytes, file.filename)

    payload = {
        "messages": [
            {
                "role": "system",
                "content": prompt
            },
            {
                "role": "user",
                "content": [
                    {
                        "type": "image_url",
                        "image_url": {
                            "url": f"data:{mime_type};base64,{base64_image}"
                        }
                    }
                ]
            }
        ],
        "extra_body": {
            "chat_template_kwargs": {"enable_thinking": True}
        },
        "response_format": {
            "type": "json_schema",
            "json_schema": {
                "name": "receipt-extraction",
                "schema": receiptExtraction.model_json_schema()
            }
        },
    }

    try:
        response = runtime_client.invoke_endpoint(
            EndpointName=endpoint_name,
            ContentType='application/json',
            Body=json.dumps(payload)
        )
        response_body = json.loads(response['Body'].read().decode())
        result = response_body['choices'][0]['message']['content']
        return {"prediction": result}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# Check Health
@app.get("/health")
def health():
    return {"status": "ok"}