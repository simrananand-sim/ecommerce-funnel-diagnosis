   # E-commerce Funnel Diagnosis

   **Business:** Online cosmetics store.
   **Question:** Where do shoppers drop off between viewing, adding to cart and purchasing, and what should be fixed first?
   **Success metric:** View-to-purchase conversion rate.

   **Tools:** MySQL, Power BI

   ## Data
   REES46 "eCommerce events history in cosmetics shop" (Kaggle, mkechinov).
   20,692,840 events, 1 Oct 2019 to 29 Feb 2020 (UTC), 1,639,358 users, 4,535,942 sessions.
   Raw files are not in this repo (too large); see the Kaggle link.

   **Known limitations**
      - No device, city or signup-date columns.
      - category_code is 98% empty, so category analysis uses category_id (500 IDs, no names).
      - brand is 42% empty.
      - One order creates several purchase rows, so funnels count distinct sessions, not events.

   ## Data cleaning
   Full log in DECISIONS.md. Summary: timestamps converted to DATETIME;
   131 negative-price rows excluded; 104,157 zero prices set to NULL and flagged (rows kept);
   raw table left unchanged.