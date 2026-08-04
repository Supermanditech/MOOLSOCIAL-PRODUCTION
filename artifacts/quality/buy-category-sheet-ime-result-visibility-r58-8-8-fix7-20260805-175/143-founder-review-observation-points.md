# R58.8.8 FIX7 founder review observation points

Candidate: `BUY-R58-CATEGORY-SHEET-IME-RESULT-VISIBILITY-FIX7`  
Status: technically/device qualified; founder disposition pending

The connected OPPO is parked on the Shop category sheet at normal Android
animation scales `1/1/1`.

1. Confirm the category sheet reads as one attached, opaque premium surface;
   `Shop categories`, Close, the labelled field and category cards are clear.
2. Confirm the field visibly says `Category search` and `Find a category`.
   The direct Android accessibility node also exposes the combined label/hint
   plus tap, focus and set-text actions; `47l-accessibility-hint-probe-final.log`
   is authoritative because legacy UIAutomator XML omits Android `hintText`.
3. Tap the field, type `shop supplies`, and confirm the complete result card
   and label stay above the keyboard. Measured clearance is 422 physical px.
4. Hide the keyboard and refocus. The query/result remain stable; Close and
   Android Back both return to the same Shop root without commerce mutation.
5. Select `Shop supplies`, open the product and use Back. Exact category/result
   context restores; Wholesale and Medicine retain independent category state.
6. Observe finite, bounded arrival/reverse motion and stable geometry. Visible
   reduced-motion testing passed immediate/static and restored normal settings.

Companion evidence is `151-founder-review-park.xml` and
`151-founder-review-park-1.png` through `-3.png`. The live device and direct
accessibility probe are primary for accessibility review.

