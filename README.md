   # E-commerce Funnel Diagnosis

   **Business:** Online cosmetics store.
   **Question:** Where do shoppers drop off between viewing, adding to cart and purchasing, and what should be fixed first?
   **Success metric:** Session conversion = sessions with a purchase / all sessions (baseline 3.43%)
   **Tools:** MySQL, Power BI

   **Finding in one line:** only 3.43% of sessions end in a purchase, and from December conversion fell about 8%, mainly after the cart, so checkout is the first place to look.

   ## Data
   REES46 "eCommerce events history in cosmetics shop" (Kaggle, mkechinov).
   20,692,840 events, 1 Oct 2019 to 29 Feb 2020 (UTC), 1,639,358 users, 4,535,942 sessions (4,535,941 after cleaning).
   Raw files are not in this repo (too large). Download them from Kaggle: https://www.kaggle.com/datasets/mkechinov/ecommerce-events-history-in-cosmetics-shop

   ## Repo contents
   - `sql/funnel_full_log.sql`: full MySQL log (load, clean, sessions, new vs returning, checks, exports)
   - `dashboard/`: Power BI file, three page screenshots, and the four CSVs the dashboard reads
   - `DECISIONS.md`: every data-cleaning and analysis decision, in order

   ## Dashboard
   ![Overview](dashboard/page1_overview.png)
   ![Shoppers](dashboard/page2_shoppers.png)
   ![Diagnosis](dashboard/page3_diagnosis.png)

   **Known limitations**
      - No device, city or signup-date columns.
      - category_code is 98% empty, so category analysis uses category_id (500 IDs, no names).
      - brand is 42% empty.
      - One order creates several purchase rows, so funnels count distinct sessions, not events.
      - Cart-to-purchase is measured within a session.
      - No promotion, price or traffic-source data, so causes are hypotheses.
      - Early October “new” labels are unreliable.

   ## Data cleaning
   Full log in DECISIONS.md. Summary: timestamps converted to DATETIME;
   131 negative-price rows excluded; 104,157 zero prices set to NULL and flagged (rows kept);
   raw table left unchanged.

   ## Key findings
      - 3.43% of sessions end in a purchase. About 82% of sessions that view never add to cart, and about 87% of cart sessions don’t purchase.
      - November was the best month (3.86%), driven mostly by returning shoppers. Cause unknown.
      - From December to February conversion fell about 8% (3.42% to 3.13%) in both new and returning shoppers. It's not a mix effect: the new share fell from 35.8% to 32.4%, which would have raised conversion.
      - From December on, cart rates were roughly flat while cart-to-purchase fell (returning 18.2% to 16.1%, new 15.3% to 13.8%). New shoppers’ cart rate also stepped down around 25 Nov to December.

   ## Recommendation (hypotheses, not proven)
   The data shows where conversion fell, not why. From December onward, cart rates stayed roughly flat while cart-to-purchase fell, so the first place to look is checkout and follow-through, not browsing.

   1. **Check checkout friction first** (payment failures, delivery cost shown late, long forms). This data has no event for these, so it needs a product team's logs.
   2. **Try a saved-cart reminder** for shoppers who added to cart but did not buy.
   3. **Do not act on the November peak.** Without promotion data its cause is unknown, and it should not be treated as a target.

   **Success metric:** session conversion back above 3.4% (the Oct to Dec baseline), then 3.7% or higher.

  ## How I would test it

   **Test:** among shoppers who add something to their cart, show half a saved-cart reminder. The other half see nothing.

   - **Primary metric:** purchase within 7 days of the cart session. The in-session baseline from this data is 12.8% (126,289 of 985,781 cart sessions). The 7-day rate is higher and not measured here, so it would be re-baselined before launch.
   - **Guardrail metric:** average order value, so a conversion lift does not come from cheaper baskets.
   - **Split by user, not by session**, so the same shopper never sees both versions.
   - **Smallest lift worth detecting:** 1.5 percentage points (12.8% to 14.3%), in line with the 1.5 to 2 point fall in cart-to-purchase seen from December to February.
   - **Sample size:** about 8,200 cart sessions per group (95% confidence, 80% power). The store sees about 6,500 cart sessions a day, so that takes under 3 days. Run it for at least 14 days to cover weekdays and weekends.
   - **Decision rule:** ship if the purchase rate rises significantly and average order value does not fall by more than 2%. Iterate if unclear. Roll back if it falls.
   - **Overall success metric stays session conversion** (baseline 3.43%). The test metric is narrower because only cart shoppers see the reminder.