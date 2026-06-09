Here is what I found when testing each scenario. 





#### VT-001 (Zero Options to Single Option Transition)

I don't see the mandatory summary stock report of deactivated variants being sent to the email. It was decided that instead of sending the email, the contents of the email will be connected to the Debug Console in the Debug environment. When running the app in the Debug environment, actual emails will be sent . 



for fresh product with no color or other option values added/selected, The SKU of the default variant is pre-loaded with the text reading "-Premium-Coffee-Mug"(all in caps)



Test steps when performed  generated the expected outcome precisely 



#### Scenario: VT-002 (Reconciliation of Pricing and Stock on Option Addition)

Test steps when performed  generated the expected outcome precisely

#### Scenario: VT-003 (Collapse to Simple Product - Stock Aggregation)

When performing the test steps, the collapse to simple product dialog pops up as soon as we trash the color option even before clicking generate variants. All options are trashed and all options disappear. All variant cards disappear. No default variant is being shown the screen reads "Variants \& Pricing (O active of O)" and even clicking the Generate Variants button does not do anything at all. Bringing in any of the earlier colors back and clicking Generate Variance does generate the event and it remembers the price and stock correctly. Since the default variant did not pop up, stock aggregation could not be verified. 



###### Scenario: VT-004 (Fresh Generation vs Reconciliation)

&#x20;It works precisely as expected. 



###### Scenario: VT-005 (Deletion of Option Values / Partial Match Reconciliation)

Note that I generated the option with a fresh generation. Let me know if I should have otherwise. 
Works as expected. What happens to the stock we were holding for the silver metallic? 



##### Scenario: VT-006 (Renaming Option Category)

Since I closed the Dialog Product Editor dialog and opened the Dialog Editor once again and entered the premium coffee mug as a product, when I moved to the Variants tab, the matte black color was not there. The Default Variant was there but I had to create the matte black color. As soon as I added that color option, the Default Variant disappeared. At that time I had no variant displayed at all. I clicked Generate Variant and used Fresh Generation and clicked Start. (let me know if I Should  have used Intelligent reconciliation here). When I renamed the matte black color preset, the selected color chip of my color option of matte black did not automatically change to matte finish. I first added the matte as the first added finish color option and then deleted the matte check. So that finish color chip was the only color option selected for the product. When I clicked Generate Variant and used Intelligent Reconciliation: Yes, the product variant was renamed and the stock and price were retained from the time when the variant was named as MAT Variant. Even with the Finish Variant product, its price and stock were retained. 



With the outcome of all these test documents I believe the only issue is that when all product options are deleted, after having a few options, the default variant does not spring back into view. I don't know whether it's true, still there in the riverpod  state or not. What else did you see?  
I'll be glad if all these tests can be automated for the future. 


