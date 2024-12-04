import logging
import azure.functions as func

def main(req: func.HttpRequest) -> func.HttpResponse:
    return func.HttpResponse(
        "Testing 1...2...3...",
        status_code=200
    )