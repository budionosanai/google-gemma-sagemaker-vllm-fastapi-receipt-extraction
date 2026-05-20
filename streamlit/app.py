import streamlit as st
import requests
import json

API_URL = "ALB DNS name (ECS custom mode) or ECS express service application URL (ECS express mode)/predict"

st.title("🧾 Receipt Extractor")

uploaded_file = st.file_uploader("Upload your receipt", type=["jpg", "jpeg", "png"])

if uploaded_file:
    st.image(uploaded_file, caption="Receipt uploaded", use_column_width=True)

    if st.button("Extract your receipt"):
        with st.spinner("Reading your receipt.."):
            uploaded_file.seek(0)
            response = requests.post(
                API_URL,
                files={"file": (uploaded_file.name, uploaded_file, uploaded_file.type)},
                timeout=30
            )
            result = response.json()["prediction"]

        try:
            data = json.loads(result)
            st.success("Successful extracted")
            st.write(f"🏪 **Store Name:** {data.get('storeName', '-')}")
            st.write(f"📅 **Purchase Date:** {data.get('purchaseDate', '-')}")
            st.write(f"💰 **Total:** {data.get('total', 0)}")
        except json.JSONDecodeError:
            st.write(result)