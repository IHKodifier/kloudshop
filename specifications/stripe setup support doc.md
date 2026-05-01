Yes, it is possible to sign up for a Stripe account while living in Pakistan specifically for the purpose of obtaining test API keys for your SaaS development. 
Since Stripe does not officially support Pakistan for live payments, you cannot activate a "live" account without UK or US business details. However, you can create a developer-focused account in Test Mode to begin coding your integration immediately. 
CliffsNotes
CliffsNotes
 +2
How to Get Stripe Dev Keys from Pakistan
Register a New Account: Go to the Stripe Registration page and sign up using your email and full name.
Select a Supported Country: When prompted for your country, choose the United Kingdom (or the United States). This allows the system to grant you access to a dashboard configured for that region's features.
Skip Activation: Once logged in, do not click "Activate your account." Activating requires legal business documentation like a UK Tax ID and local bank details.
Enable Test Mode: Ensure the "Test Mode" toggle in the top-right of your dashboard is turned ON.
Retrieve Keys: Navigate to Developers > API Keys. You will find your pk_test_... (Publishable) and sk_test_... (Secret) keys ready for use. 
Stripe Documentation
Stripe Documentation
 +5
Capabilities in Test Mode
Mock Payments: Use Stripe's test card numbers (e.g., 4242 4242 4242 4242) to simulate successful or failed transactions.
Webhooks: You can set up and test webhooks locally using the Stripe CLI to handle events like checkout.session.completed.
Subscriptions: You can create products and test recurring billing cycles without any verification.
Sandboxes: You can use isolated sandboxes to experiment with different account configurations. 
Stripe Documentation
Stripe Documentation
 +4
Key Limitations
Live Mode Blocked: You will not be able to toggle into "Live Mode" or receive real money until you provide your UK LTD company details and a supported bank account (e.g., through Wise Business or Payoneer).
Email Verification: Stripe will require you to verify your email address to keep the account active, even in test mode. 
Webzeto
Webzeto
 +2
Would you like to explore Stripe alternatives that support Pakistan for live payments, or do you need help setting up the Stripe CLI for local development?