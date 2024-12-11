import httpx

api_url = 'https://b2eb-91-188-188-116.ngrok-free.app/api/'
app_url = 'https://b2eb-91-188-188-116.ngrok-free.app'
admin_url = 'https://b2eb-91-188-188-116.ngrok-free.app/admin/'

async def check_key_via_api(key: str) -> int:
    try:
        url = f"{api_url}check_key"
        data = {"key": key}
        async with httpx.AsyncClient() as client:
            response = await client.post(url, json=data)
        if response.status_code == 200:
            result = response.json()
            return result.get("exists", 0)
        else:
            raise Exception(f"Error: {response.status_code} - {response.text}")

    except Exception as e:
        print(f"Failed to check key via API: {str(e)}")
        return 0


async def add_worker_via_api(tg_id: int, username: str, full_name: str, key: str) -> dict:
    try:
        url = f"{api_url}add_worker"
        data = {
            "tg_id": tg_id,
            "username": username,
            "full_name": full_name,
            "key": key
        }
        async with httpx.AsyncClient() as client:
            response = await client.post(url, json=data)

        if response.status_code == 200:
            return response.json()
        else:
            raise Exception(f"Error: {response.status_code} - {response.text}")

    except Exception as e:
        print(f"Failed to add worker via API: {str(e)}")
        return {"error": str(e)}
    
async def check_admin(tg_id: int) -> int:
    try:
        url = f"{api_url}check_admin"
        data = {"tg_id": tg_id}
        async with httpx.AsyncClient() as client:
            response = await client.post(url, json=data)
        if response.status_code == 200:
            result = response.json()
            return result.get("exists", 0)
        else:
            raise Exception(f"Error: {response.status_code} - {response.text}")

    except Exception as e:
        print(f"Failed to check key via API: {str(e)}")
        return 0