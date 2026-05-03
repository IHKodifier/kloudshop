import uuid
from datetime import datetime, timedelta
from decimal import Decimal

class StripeMock:
    async def create_payment_intent(self, amount: int, currency: str, metadata: dict):
        """
        Mock Stripe PaymentIntent for B2C orders.
        """
        return {
            "id": f"pi_{uuid.uuid4().hex[:16]}",
            "client_secret": f"secret_{uuid.uuid4().hex}",
            "amount": amount,
            "currency": currency
        }

    async def create_invoice(self, amount: int, currency: str, customer_email: str, due_date: datetime, metadata: dict):
        """
        Mock Stripe Invoice creation for B2B Net-Terms.
        """
        invoice_id = f"in_{uuid.uuid4().hex[:16]}"
        return {
            "id": invoice_id,
            "amount": amount,
            "currency": currency,
            "customer_email": customer_email,
            "due_date": due_date,
            "status": "open",
            "hosted_invoice_url": f"https://stripe.com/invoice/{invoice_id}"
        }

    async def retrieve_payment_intent(self, pi_id: str):
        return {
            "id": pi_id,
            "status": "succeeded",
            "amount": 1000,
            "currency": "usd"
        }

stripe_mock = StripeMock()
