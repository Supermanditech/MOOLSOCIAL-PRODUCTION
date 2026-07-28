(() => {
  "use strict";

  const app = document.querySelector("[data-buy-app]");
  if (!app) return;

  const money = (value) =>
    new Intl.NumberFormat("en-IN", {
      style: "currency",
      currency: "INR",
      maximumFractionDigits: 0,
    }).format(value);

  const escapeHtml = (value) =>
    String(value)
      .replaceAll("&", "&amp;")
      .replaceAll("<", "&lt;")
      .replaceAll(">", "&gt;")
      .replaceAll('"', "&quot;")
      .replaceAll("'", "&#039;");

  const unitMoney = (value) =>
    new Intl.NumberFormat("en-IN", {
      style: "currency",
      currency: "INR",
      maximumFractionDigits: 2,
    }).format(value);

  const art = {
    tomato: `
      <svg viewBox="0 0 120 105" aria-hidden="true">
        <ellipse cx="60" cy="88" rx="40" ry="8" fill="rgba(77,31,18,.12)"/>
        <circle cx="42" cy="55" r="25" fill="#e84a3c"/>
        <circle cx="73" cy="54" r="27" fill="#f05845"/>
        <circle cx="62" cy="71" r="24" fill="#d83933"/>
        <path d="m59 29 5 11 13-6-7 12 14 4-15 3 6 13-13-8-9 11 2-15-15-1 14-6-8-12z" fill="#248d34"/>
        <circle cx="36" cy="47" r="5" fill="rgba(255,255,255,.24)"/>
      </svg>`,
    atta: `
      <svg viewBox="0 0 120 105" aria-hidden="true">
        <ellipse cx="60" cy="91" rx="34" ry="7" fill="rgba(77,31,18,.12)"/>
        <path d="M35 18h50l7 17-6 55H34l-6-55z" fill="#f4d89e"/>
        <path d="M30 36h60l-2 17H32z" fill="#f09b38"/>
        <circle cx="60" cy="66" r="15" fill="#fff9e9"/>
        <path d="M52 74c9-5 13-12 14-22-8 4-13 11-14 22zm10-1c-1-8 1-15 7-21" fill="none" stroke="#43843c" stroke-width="3" stroke-linecap="round"/>
        <text x="60" y="28" text-anchor="middle" fill="#5b3b1c" font-size="9" font-weight="800">CHAKKI ATTA</text>
      </svg>`,
    oil: `
      <svg viewBox="0 0 120 105" aria-hidden="true">
        <ellipse cx="60" cy="91" rx="28" ry="7" fill="rgba(77,31,18,.12)"/>
        <path d="M46 21h28v10l7 8v49H39V39l7-8z" fill="#f4bd2f"/>
        <path d="M50 13h20v12H50z" fill="#1e7740"/>
        <path d="M43 49h34v25H43z" fill="#fff8dd"/>
        <circle cx="60" cy="61" r="9" fill="#f7c83b"/>
        <path d="M60 52c7 8 7 14 0 18-7-4-7-10 0-18z" fill="#d69318"/>
        <path d="M42 39h37" stroke="#fff" stroke-width="3" opacity=".5"/>
      </svg>`,
    rice: `
      <svg viewBox="0 0 120 105" aria-hidden="true">
        <ellipse cx="60" cy="91" rx="34" ry="7" fill="rgba(77,31,18,.12)"/>
        <path d="M35 22h50l7 65H28z" fill="#f7f3e8"/>
        <path d="M35 22h50l-5 14H40z" fill="#5e56a3"/>
        <path d="M42 61c13-22 28-26 38-28-3 17-14 35-38 42z" fill="#6c9d48"/>
        <path d="M48 69c11-15 20-23 29-29" fill="none" stroke="#fff" stroke-width="3" stroke-linecap="round"/>
        <text x="60" y="82" text-anchor="middle" fill="#292361" font-size="8" font-weight="800">BASMATI</text>
      </svg>`,
    soap: `
      <svg viewBox="0 0 120 105" aria-hidden="true">
        <ellipse cx="60" cy="88" rx="39" ry="7" fill="rgba(77,31,18,.12)"/>
        <rect x="24" y="34" width="72" height="50" rx="14" fill="#84c690"/>
        <rect x="29" y="39" width="62" height="40" rx="11" fill="#a8dfae"/>
        <path d="M46 64c12-21 24-22 32-22-4 14-12 24-32 29z" fill="#29833a"/>
        <circle cx="87" cy="28" r="8" fill="#dff5e1"/>
        <circle cx="98" cy="19" r="5" fill="#fff"/>
      </svg>`,
    notebook: `
      <svg viewBox="0 0 120 105" aria-hidden="true">
        <ellipse cx="60" cy="91" rx="36" ry="7" fill="rgba(77,31,18,.12)"/>
        <path d="M33 17h56v72H33z" fill="#fff"/>
        <path d="M39 17h50v72H39z" fill="#6570b7"/>
        <path d="M46 29h35v44H46z" fill="#fff"/>
        <path d="M52 39h23M52 47h23M52 55h19M52 63h21" stroke="#c0c4df" stroke-width="2"/>
        <path d="M34 24h8M34 34h8M34 44h8M34 54h8M34 64h8M34 74h8" stroke="#f1b34c" stroke-width="3" stroke-linecap="round"/>
      </svg>`,
  };

  const packagedArt = (label, accent, soft) => `
    <svg viewBox="0 0 120 105" aria-hidden="true">
      <ellipse cx="60" cy="91" rx="35" ry="7" fill="rgba(35,28,18,.12)"/>
      <path d="M35 21h50l7 66H28z" fill="${soft}"/>
      <path d="M35 21h50l-3 14H38z" fill="${accent}"/>
      <rect x="38" y="42" width="44" height="31" rx="10" fill="#fff" opacity=".94"/>
      <circle cx="60" cy="51" r="6" fill="${accent}" opacity=".9"/>
      <path d="M49 64h22" stroke="${accent}" stroke-width="3" stroke-linecap="round" opacity=".82"/>
      <text x="60" y="82" text-anchor="middle" fill="#11112d" font-size="8" font-weight="900">${label}</text>
    </svg>`;

  const products = [
    {
      id: "tomato",
      title: "Fresh tomatoes",
      brand: "Farm fresh",
      category: "fresh-produce",
      businessCategory: "fresh-produce",
      visual: "tomato",
      colors: ["#fff0e6", "#e9f6e7"],
      protection: "Refund available for a verified quality issue within 24 hours.",
      personal: {
        pack: "500 g pack",
        price: 37,
        unit: "₹74/kg",
        badge: "Lowest delivered price",
        stock: "In stock",
        seller: "Shree Balaji Fresh",
        sellerType: "Verified retailer",
        delivery: "12 minutes",
        location: "1.2 km away",
        returnTerm: "Quality refund within 24 hours",
        packs: [
          ["500 g", "₹37"],
          ["1 kg", "₹70"],
        ],
        sellers: [
          ["SB", "Shree Balaji Fresh", "Verified retailer · 12 min", 37, "Lowest delivered"],
          ["JF", "Jodhpur Fresh Mart", "Verified retailer · 18 min", 39, "Faster pickup"],
          ["GK", "Green Kisan Store", "Verified shop · 28 min", 41, "Top quality rating"],
        ],
      },
      business: {
        pack: "10 kg crate",
        price: 580,
        unit: "₹58/kg",
        badge: "Best landed cost",
        stock: "42 crates available",
        seller: "Jodhpur Fresh Supply",
        sellerType: "Verified wholesaler",
        delivery: "Tomorrow by 10:30 am",
        location: "Serves 342003",
        returnTerm: "Shortage or quality claim within 12 hours",
        packs: [
          ["10 kg crate", "MOQ 2"],
          ["20 kg crate", "MOQ 1"],
        ],
        breaks: [
          ["2–4 crates", "₹580 each"],
          ["5–9 crates", "₹555 each"],
          ["10+ crates", "₹532 each"],
        ],
        terms: [
          ["Tax", "GST included"],
          ["Freight", "Free above ₹2,000"],
          ["Payment", "UPI or bank transfer"],
          ["Credit", "7 days · approved"],
        ],
        sellers: [
          ["JF", "Jodhpur Fresh Supply", "Verified wholesaler · next morning", 580, "Best landed cost"],
          ["KM", "Kisan Mandi Direct", "Verified producer group · next day", 565, "Freight ₹90"],
          ["RF", "Rajasthan Fresh Hub", "Verified distributor · same day", 610, "Fastest delivery"],
        ],
      },
    },
    {
      id: "atta",
      title: "Stone-ground wheat atta",
      brand: "Daily staples",
      category: "grains-pulses",
      businessCategory: "grains-pulses",
      visual: "atta",
      colors: ["#fff2d9", "#f6efe5"],
      protection: "Sealed-pack return available within seven days.",
      personal: {
        pack: "5 kg bag",
        price: 279,
        unit: "₹55.80/kg",
        badge: "Best value",
        stock: "In stock",
        seller: "Sardarpura Supermart",
        sellerType: "Verified retailer",
        delivery: "Today by 7:30 pm",
        location: "2.0 km away",
        returnTerm: "Sealed pack · 7-day return",
        packs: [
          ["5 kg", "₹279"],
          ["10 kg", "₹535"],
        ],
        sellers: [
          ["SS", "Sardarpura Supermart", "Verified retailer · today", 279, "Best value"],
          ["RM", "Rajasthan Mart", "Verified retailer · 22 min", 284, "Fastest delivery"],
          ["GB", "Ghar Bazaar", "Verified shop · tomorrow", 272, "Delivery ₹18"],
        ],
      },
      business: {
        pack: "Case of 10 × 5 kg",
        price: 2420,
        unit: "₹48.40/kg",
        badge: "Lowest delivered price",
        stock: "18 cases available",
        seller: "Marwar Foods Distribution",
        sellerType: "Verified distributor",
        delivery: "Tomorrow by 2:00 pm",
        location: "Serves 342003",
        returnTerm: "Sealed case return within three days",
        packs: [
          ["10 × 5 kg", "MOQ 2"],
          ["5 × 10 kg", "MOQ 2"],
        ],
        breaks: [
          ["2–4 cases", "₹2,420"],
          ["5–9 cases", "₹2,360"],
          ["10+ cases", "₹2,295"],
        ],
        terms: [
          ["Tax", "GST included"],
          ["Freight", "Included"],
          ["Payment", "UPI or bank transfer"],
          ["Credit", "7 days · approved"],
        ],
        sellers: [
          ["MF", "Marwar Foods Distribution", "Verified distributor · next day", 2420, "Lowest delivered"],
          ["AF", "Aravali Flour Mill", "Verified manufacturer · two days", 2310, "Freight ₹140"],
          ["JD", "Jai Durga Wholesale", "Verified wholesaler · next day", 2480, "Flexible MOQ"],
        ],
      },
    },
    {
      id: "oil",
      title: "Refined sunflower oil",
      brand: "Kitchen essentials",
      category: "oils-ghee",
      businessCategory: "oils-ghee",
      visual: "oil",
      colors: ["#fff3bd", "#eff7d9"],
      protection: "Damaged or leaking packs are replaced at no extra charge.",
      personal: {
        pack: "5 L can",
        price: 835,
        unit: "₹167/L",
        badge: "Lowest delivered price",
        stock: "Only 4 left",
        seller: "Ghar Bazaar",
        sellerType: "Verified retailer",
        delivery: "Today by 8:00 pm",
        location: "2.6 km away",
        returnTerm: "Replacement for damaged seal",
        packs: [
          ["5 L can", "₹835"],
          ["1 L pouch", "₹173"],
        ],
        sellers: [
          ["GB", "Ghar Bazaar", "Verified retailer · today", 835, "Lowest delivered"],
          ["SS", "Sardarpura Supermart", "Verified retailer · 35 min", 849, "Fastest delivery"],
          ["RF", "Rasoi Fresh", "Verified shop · tomorrow", 819, "Delivery ₹24"],
        ],
      },
      business: {
        pack: "Case of 4 × 5 L",
        price: 3096,
        unit: "₹154.80/L",
        badge: "Manufacturer offer",
        stock: "27 cases available",
        seller: "Surya Oils India",
        sellerType: "Verified manufacturer",
        delivery: "Dispatch in one day",
        location: "Delivered to 342003",
        returnTerm: "Transit damage replacement",
        packs: [
          ["4 × 5 L", "MOQ 2"],
          ["15 × 1 L", "MOQ 3"],
        ],
        breaks: [
          ["2–4 cases", "₹3,096"],
          ["5–9 cases", "₹3,020"],
          ["10+ cases", "₹2,940"],
        ],
        terms: [
          ["Tax", "GST extra at invoice"],
          ["Freight", "Included above 5 cases"],
          ["Payment", "Bank transfer"],
          ["Credit", "Not enabled"],
        ],
        sellers: [
          ["SO", "Surya Oils India", "Verified manufacturer · one day", 3096, "Manufacturer offer"],
          ["MD", "Marwar Distribution", "Verified distributor · next day", 3150, "Freight included"],
          ["JW", "Jodhpur Wholesale", "Verified wholesaler · same day", 3220, "Fastest delivery"],
        ],
      },
    },
    {
      id: "rice",
      title: "Premium basmati rice",
      brand: "Daily staples",
      category: "grains-pulses",
      businessCategory: "grains-pulses",
      visual: "rice",
      colors: ["#f6f1ff", "#ecf5e8"],
      protection: "Sealed-pack return available within seven days.",
      personal: {
        pack: "5 kg bag",
        price: 395,
        unit: "₹79/kg",
        badge: "Popular nearby",
        stock: "In stock",
        seller: "Rajasthan Mart",
        sellerType: "Verified retailer",
        delivery: "25 minutes",
        location: "1.8 km away",
        returnTerm: "Sealed pack · 7-day return",
        packs: [
          ["5 kg", "₹395"],
          ["10 kg", "₹770"],
        ],
        sellers: [
          ["RM", "Rajasthan Mart", "Verified retailer · 25 min", 395, "Popular nearby"],
          ["GB", "Ghar Bazaar", "Verified retailer · 40 min", 389, "Delivery ₹18"],
          ["SS", "Sardarpura Supermart", "Verified retailer · today", 405, "Top seller rating"],
        ],
      },
      business: {
        pack: "25 kg bag",
        price: 1690,
        unit: "₹67.60/kg",
        badge: "Best landed cost",
        stock: "64 bags available",
        seller: "Thar Grains Wholesale",
        sellerType: "Verified wholesaler",
        delivery: "Tomorrow by 5:00 pm",
        location: "Serves 342003",
        returnTerm: "Sealed bag return within three days",
        packs: [
          ["25 kg bag", "MOQ 4"],
          ["50 kg bag", "MOQ 2"],
        ],
        breaks: [
          ["4–9 bags", "₹1,690"],
          ["10–19 bags", "₹1,640"],
          ["20+ bags", "₹1,585"],
        ],
        terms: [
          ["Tax", "GST included"],
          ["Freight", "Included"],
          ["Payment", "UPI or bank transfer"],
          ["Credit", "7 days · approved"],
        ],
        sellers: [
          ["TG", "Thar Grains Wholesale", "Verified wholesaler · next day", 1690, "Best landed cost"],
          ["RG", "Rajasthan Grain Co.", "Verified distributor · two days", 1610, "Freight ₹220"],
          ["KF", "Kisan Foods", "Verified manufacturer · three days", 1575, "MOQ 10 bags"],
        ],
      },
    },
    {
      id: "soap",
      title: "Herbal bathing soap",
      brand: "Personal care",
      category: "personal-care",
      businessCategory: "personal-care",
      visual: "soap",
      colors: ["#e9f8e7", "#f4f8ed"],
      protection: "Unopened packs can be returned within seven days.",
      personal: {
        pack: "Pack of 4",
        price: 164,
        unit: "₹41 each",
        badge: "Best value",
        stock: "In stock",
        seller: "Ghar Bazaar",
        sellerType: "Verified retailer",
        delivery: "30 minutes",
        location: "2.6 km away",
        returnTerm: "Unopened pack · 7-day return",
        packs: [
          ["Pack of 4", "₹164"],
          ["Pack of 8", "₹312"],
        ],
        sellers: [
          ["GB", "Ghar Bazaar", "Verified retailer · 30 min", 164, "Best value"],
          ["RM", "Rajasthan Mart", "Verified retailer · 45 min", 169, "Popular nearby"],
        ],
      },
      business: {
        pack: "Case of 48",
        price: 1680,
        unit: "₹35 each",
        badge: "Lowest delivered price",
        stock: "16 cases available",
        seller: "Care Products Distribution",
        sellerType: "Verified distributor",
        delivery: "Within two days",
        location: "Delivered to 342003",
        returnTerm: "Sealed case return within three days",
        packs: [
          ["Case of 48", "MOQ 2"],
          ["Case of 96", "MOQ 1"],
        ],
        breaks: [
          ["2–4 cases", "₹1,680"],
          ["5–9 cases", "₹1,620"],
          ["10+ cases", "₹1,560"],
        ],
        terms: [
          ["Tax", "GST extra at invoice"],
          ["Freight", "Included"],
          ["Payment", "UPI or bank transfer"],
          ["Credit", "Not enabled"],
        ],
        sellers: [
          ["CP", "Care Products Distribution", "Verified distributor · two days", 1680, "Lowest delivered"],
          ["HB", "Herbal Brands India", "Verified manufacturer · three days", 1580, "Freight ₹180"],
        ],
      },
    },
    {
      id: "notebook",
      title: "A4 ruled notebooks",
      brand: "Home and school",
      category: "stationery-office",
      businessCategory: "stationery-office",
      visual: "notebook",
      colors: ["#ececff", "#fff2df"],
      protection: "Damaged items are replaced at no extra charge.",
      personal: {
        pack: "Pack of 6",
        price: 210,
        unit: "₹35 each",
        badge: "Popular nearby",
        stock: "In stock",
        seller: "Family Stationery",
        sellerType: "Verified shop",
        delivery: "Today by 6:30 pm",
        location: "1.4 km away",
        returnTerm: "Unused pack · 7-day return",
        packs: [
          ["Pack of 6", "₹210"],
          ["Pack of 12", "₹398"],
        ],
        sellers: [
          ["FS", "Family Stationery", "Verified shop · today", 210, "Popular nearby"],
          ["SB", "School Bazaar", "Verified retailer · tomorrow", 198, "Delivery ₹18"],
        ],
      },
      business: {
        pack: "Carton of 120",
        price: 3480,
        unit: "₹29 each",
        badge: "Best landed cost",
        stock: "12 cartons available",
        seller: "Rajasthan Paper Products",
        sellerType: "Verified manufacturer",
        delivery: "Within three days",
        location: "Delivered to 342003",
        returnTerm: "Transit damage replacement",
        packs: [
          ["Carton of 120", "MOQ 1"],
          ["Carton of 240", "MOQ 1"],
        ],
        breaks: [
          ["1–2 cartons", "₹3,480"],
          ["3–5 cartons", "₹3,360"],
          ["6+ cartons", "₹3,210"],
        ],
        terms: [
          ["Tax", "GST extra at invoice"],
          ["Freight", "Included above 3 cartons"],
          ["Payment", "Bank transfer"],
          ["Credit", "7 days · approved"],
        ],
        sellers: [
          ["RP", "Rajasthan Paper Products", "Verified manufacturer · three days", 3480, "Best landed cost"],
          ["ES", "Education Supply Hub", "Verified wholesaler · two days", 3590, "Fastest delivery"],
        ],
      },
    },
  ];

  const commercePartners = {
    "fresh-produce": ["Jodhpur Fresh Mart", "Marwar Fresh Supply", "Verified producer group"],
    "dairy-bakery": ["Family Dairy & Bake", "Rajasthan Chilled Distribution", "Verified distributor"],
    "meat-eggs": ["Safe Protein Store", "Marwar Cold Chain Foods", "Verified distributor"],
    "grains-pulses": ["Rajasthan Mart", "Thar Grains Wholesale", "Verified wholesaler"],
    "oils-ghee": ["Ghar Bazaar", "Surya Oils India", "Verified manufacturer"],
    "spices-condiments": ["Masala Ghar", "Marwar Spice Works", "Verified manufacturer"],
    "breakfast-instant": ["Morning Supply", "Rajasthan Foods Distribution", "Verified distributor"],
    "packaged-foods": ["Family Supermart", "Jodhpur Packaged Foods Hub", "Verified distributor"],
    "snacks-confectionery": ["Snack Street", "Marwar Snacks Distribution", "Verified distributor"],
    beverages: ["Daily Drinks Store", "Rajasthan Beverage Supply", "Verified distributor"],
    "frozen-chilled": ["Fresh & Frozen", "Jodhpur Cold Supply", "Verified distributor"],
    "personal-care": ["Care Corner", "Marwar Care Distribution", "Verified distributor"],
    "beauty-grooming": ["Beauty Supply", "Rajasthan Beauty Supply", "Verified distributor"],
    "home-care": ["Home Essentials", "Jodhpur Home Care Supply", "Verified distributor"],
    "laundry-cleaning": ["Clean Home Store", "Marwar Cleaning Products", "Verified manufacturer"],
    "baby-care": ["Baby Needs", "Rajasthan Baby Care Supply", "Verified distributor"],
    "health-wellness": ["Wellness Store", "Marwar Wellness Distribution", "Verified distributor"],
    "pet-care": ["Pet Family Store", "Rajasthan Pet Supply", "Verified distributor"],
    "kitchen-disposables": ["Kitchen Needs", "Marwar Foodservice Supply", "Verified wholesaler"],
    "horeca-supplies": ["Kitchen Needs", "Marwar Foodservice Supply", "Verified wholesaler"],
    "retail-supplies": ["Store Essentials", "Rajasthan Retail Supply", "Verified manufacturer"],
    "stationery-office": ["Family Stationery", "Rajasthan Paper Products", "Verified manufacturer"],
  };

  const existingProductSubcategories = {
    tomato: ["vegetables"],
    atta: ["flour"],
    oil: ["edible-oils"],
    rice: ["rice"],
    soap: ["bath-body"],
    notebook: ["notebooks"],
    onion: ["vegetables"],
    milk: ["milk-curd"],
    bread: ["bread-bakery"],
    eggs: ["eggs"],
    chicken: ["poultry"],
    ghee: ["ghee"],
    turmeric: ["ground-spices"],
    cumin: ["whole-spices"],
    poha: ["traditional-breakfast"],
    oats: ["cereals"],
    noodles: ["noodles-pasta"],
    pasta: ["noodles-pasta"],
    biscuits: ["biscuits"],
    namkeen: ["savouries"],
    tea: ["tea-coffee"],
    juice: ["juices"],
    peas: ["frozen-veg"],
    "ice-cream": ["dairy-desserts"],
    toothpaste: ["oral-care"],
    shampoo: ["hair-care"],
    "face-wash": ["skin-care"],
    "floor-cleaner": ["floor-bathroom"],
    "toilet-cleaner": ["floor-bathroom"],
    detergent: ["laundry"],
    dishwash: ["dish-care"],
    diapers: ["diapers-wipes"],
    "baby-wipes": ["diapers-wipes"],
    chyawanprash: ["herbal-wellness"],
    protein: ["nutrition"],
    "dog-food": ["dog-care"],
    "cat-food": ["cat-care"],
    foil: ["food-storage"],
    "paper-cups": ["tableware"],
    "thermal-rolls": ["shop-supplies", "pos-consumables"],
    "price-labels": ["shop-supplies", "pricing-labels"],
    pencils: ["writing"],
  };

  const catalogueRows = [
    { id: "onion", title: "Fresh red onions", brand: "Farm fresh", category: "fresh-produce", label: "ONION", accent: "#b54a72", soft: "#f8dce8", retail: ["1 kg pack", 42, "₹42/kg"], trade: ["25 kg sack", 775, "₹31/kg"], tags: ["vegetable", "pyaz"] },
    { id: "milk", title: "Toned fresh milk", brand: "Daily dairy", category: "dairy-bakery", label: "MILK", accent: "#2674c7", soft: "#e3f2ff", retail: ["1 L pouch", 66, "₹66/L"], trade: ["Crate of 12 × 1 L", 660, "₹55/L"], tags: ["doodh", "chilled"] },
    { id: "bread", title: "Whole wheat bread", brand: "Fresh bakery", category: "dairy-bakery", label: "BREAD", accent: "#b7722b", soft: "#fae6c7", retail: ["400 g loaf", 45, "₹112.50/kg"], trade: ["Tray of 24 loaves", 720, "₹30/loaf"], tags: ["bakery", "loaf"] },
    { id: "eggs", title: "Farm fresh eggs", brand: "Protein foods", category: "meat-eggs", label: "EGGS", accent: "#d99124", soft: "#fff0c7", retail: ["6 eggs", 89, "₹14.83/egg"], trade: ["Tray lot of 180 eggs", 1600, "₹8.89/egg"], tags: ["anda", "protein"] },
    { id: "chicken", title: "Fresh chicken curry cut", brand: "Cold-chain fresh", category: "meat-eggs", label: "CHICKEN", accent: "#b94c45", soft: "#ffe4df", retail: ["1 kg pack", 285, "₹285/kg"], trade: ["10 kg foodservice pack", 2400, "₹240/kg"], tags: ["poultry", "meat"] },
    { id: "ghee", title: "Pure cow ghee", brand: "Kitchen essentials", category: "oils-ghee", label: "GHEE", accent: "#df9e15", soft: "#fff0b8", retail: ["1 L jar", 625, "₹625/L"], trade: ["Case of 10 × 1 L", 5700, "₹570/L"], tags: ["clarified butter", "dairy"] },
    { id: "turmeric", title: "Turmeric powder", brand: "Everyday spices", category: "spices-condiments", label: "HALDI", accent: "#e2a100", soft: "#fff0a8", retail: ["200 g pack", 78, "₹390/kg"], trade: ["10 kg trade pack", 3100, "₹310/kg"], tags: ["haldi", "masala"] },
    { id: "cumin", title: "Whole cumin seeds", brand: "Everyday spices", category: "spices-condiments", label: "JEERA", accent: "#8b6429", soft: "#ead7b5", retail: ["200 g pack", 95, "₹475/kg"], trade: ["10 kg trade pack", 3900, "₹390/kg"], tags: ["jeera", "masala"] },
    { id: "poha", title: "Thick breakfast poha", brand: "Morning staples", category: "breakfast-instant", label: "POHA", accent: "#d88b2f", soft: "#ffead0", retail: ["1 kg pack", 72, "₹72/kg"], trade: ["25 kg sack", 1250, "₹50/kg"], tags: ["flattened rice", "breakfast"] },
    { id: "oats", title: "Wholegrain rolled oats", brand: "Morning staples", category: "breakfast-instant", label: "OATS", accent: "#7a9b3d", soft: "#e8f1cf", retail: ["1 kg pack", 195, "₹195/kg"], trade: ["Case of 12 × 1 kg", 1980, "₹165/kg"], tags: ["breakfast", "cereal"] },
    { id: "noodles", title: "Instant masala noodles", brand: "Quick meals", category: "packaged-foods", label: "NOODLES", accent: "#d94c32", soft: "#ffe1d8", retail: ["Pack of 6", 84, "₹14/pack"], trade: ["Carton of 120 packs", 1080, "₹9/pack"], tags: ["instant", "ready to cook"] },
    { id: "pasta", title: "Durum wheat pasta", brand: "Quick meals", category: "packaged-foods", label: "PASTA", accent: "#d49a20", soft: "#fff0c2", retail: ["1 kg pack", 110, "₹110/kg"], trade: ["25 kg foodservice pack", 2250, "₹90/kg"], tags: ["macaroni", "ready to cook"] },
    { id: "biscuits", title: "Glucose biscuits", brand: "Tea-time favourites", category: "snacks-confectionery", label: "BISCUIT", accent: "#c47426", soft: "#f9dfc2", retail: ["Pack of 6", 60, "₹10/pack"], trade: ["Carton of 240 packs", 1650, "₹6.88/pack"], tags: ["cookies", "snack"] },
    { id: "namkeen", title: "Classic bhujia namkeen", brand: "Tea-time favourites", category: "snacks-confectionery", label: "NAMKEEN", accent: "#d36f1d", soft: "#ffe3bf", retail: ["400 g pack", 85, "₹212.50/kg"], trade: ["Case of 30 × 400 g", 1680, "₹140/kg"], tags: ["bhujia", "snack"] },
    { id: "tea", title: "Strong leaf tea", brand: "Daily beverages", category: "beverages", label: "TEA", accent: "#6e8f31", soft: "#e4edcb", retail: ["500 g pack", 265, "₹530/kg"], trade: ["10 kg trade pack", 4150, "₹415/kg"], tags: ["chai", "hot drink"] },
    { id: "juice", title: "Mixed fruit juice", brand: "Daily beverages", category: "beverages", label: "JUICE", accent: "#e77d20", soft: "#ffe2bd", retail: ["1 L carton", 110, "₹110/L"], trade: ["Case of 24 × 1 L", 2100, "₹87.50/L"], tags: ["fruit drink", "cold drink"] },
    { id: "peas", title: "Frozen green peas", brand: "Frozen fresh", category: "frozen-chilled", label: "PEAS", accent: "#3c923f", soft: "#dff0d9", retail: ["1 kg pack", 155, "₹155/kg"], trade: ["20 kg cold-chain case", 2800, "₹140/kg"], tags: ["matar", "frozen vegetable"] },
    { id: "ice-cream", title: "Vanilla ice cream", brand: "Frozen favourites", category: "frozen-chilled", label: "ICE CREAM", accent: "#8867bb", soft: "#ede2fa", retail: ["1 L tub", 220, "₹220/L"], trade: ["Case of 12 × 1 L", 2400, "₹200/L"], tags: ["dessert", "chilled"] },
    { id: "toothpaste", title: "Family fluoride toothpaste", brand: "Personal care", category: "personal-care", label: "PASTE", accent: "#2779b9", soft: "#dceeff", retail: ["Pack of 2", 190, "₹95/tube"], trade: ["Case of 24 tubes", 1680, "₹70/tube"], tags: ["oral care", "dental"] },
    { id: "shampoo", title: "Daily care shampoo", brand: "Beauty & grooming", category: "beauty-grooming", label: "SHAMPOO", accent: "#7d56b6", soft: "#eadffa", retail: ["650 ml bottle", 299, "₹460/L"], trade: ["Case of 20 bottles", 4800, "₹240/bottle"], tags: ["hair care", "beauty"] },
    { id: "face-wash", title: "Gentle face wash", brand: "Beauty & grooming", category: "beauty-grooming", label: "FACE WASH", accent: "#318eb0", soft: "#dcf3fa", retail: ["100 ml tube", 179, "₹1.79/ml"], trade: ["Case of 24 tubes", 3200, "₹133.33/tube"], tags: ["skin care", "beauty"] },
    { id: "floor-cleaner", title: "Disinfectant floor cleaner", brand: "Home care", category: "home-care", label: "FLOOR", accent: "#258b82", soft: "#d7f0eb", retail: ["2 L bottle", 210, "₹105/L"], trade: ["20 L institutional can", 2800, "₹140/L"], tags: ["disinfectant", "cleaning"] },
    { id: "toilet-cleaner", title: "Power toilet cleaner", brand: "Home care", category: "home-care", label: "TOILET", accent: "#235eb1", soft: "#dbe7fb", retail: ["2 L bottle", 195, "₹97.50/L"], trade: ["20 L institutional can", 2500, "₹125/L"], tags: ["bathroom", "cleaning"] },
    { id: "detergent", title: "Front-load detergent powder", brand: "Laundry care", category: "laundry-cleaning", label: "DETERGENT", accent: "#2d69bd", soft: "#dce9fc", retail: ["5 kg pack", 590, "₹118/kg"], trade: ["25 kg trade pack", 2200, "₹88/kg"], tags: ["washing powder", "laundry"] },
    { id: "dishwash", title: "Lemon dishwash bars", brand: "Cleaning essentials", category: "laundry-cleaning", label: "DISHWASH", accent: "#64a521", soft: "#e4f2ce", retail: ["Pack of 4", 95, "₹23.75/bar"], trade: ["Carton of 96 bars", 1600, "₹16.67/bar"], tags: ["utensil cleaner", "kitchen"] },
    { id: "diapers", title: "Baby diapers medium", brand: "Baby care", category: "baby-care", label: "DIAPERS", accent: "#5c8fcd", soft: "#e0efff", retail: ["42 diapers", 699, "₹16.64/diaper"], trade: ["Case of 8 packs", 5600, "₹700/pack"], tags: ["baby nappy", "infant"] },
    { id: "baby-wipes", title: "Unscented baby wipes", brand: "Baby care", category: "baby-care", label: "WIPES", accent: "#db6f97", soft: "#fbe1ea", retail: ["72 wipes", 180, "₹2.50/wipe"], trade: ["Case of 18 packs", 2400, "₹133.33/pack"], tags: ["baby hygiene", "infant"] },
    { id: "chyawanprash", title: "Herbal chyawanprash", brand: "Daily wellness", category: "health-wellness", label: "WELLNESS", accent: "#7a5d31", soft: "#eee0c7", retail: ["1 kg jar", 360, "₹360/kg"], trade: ["Case of 12 × 1 kg", 3400, "₹283.33/kg"], tags: ["immunity", "herbal"] },
    { id: "protein", title: "Everyday nutrition protein", brand: "Daily wellness", category: "health-wellness", label: "PROTEIN", accent: "#b05f35", soft: "#f7dfd2", retail: ["1 kg jar", 899, "₹899/kg"], trade: ["Case of 10 × 1 kg", 7800, "₹780/kg"], tags: ["nutrition", "supplement"] },
    { id: "dog-food", title: "Adult dog food", brand: "Pet nutrition", category: "pet-care", label: "DOG FOOD", accent: "#9a6b36", soft: "#f1dfc6", retail: ["3 kg bag", 699, "₹233/kg"], trade: ["25 kg breeder pack", 4850, "₹194/kg"], tags: ["pet food", "dog"] },
    { id: "cat-food", title: "Adult cat food", brand: "Pet nutrition", category: "pet-care", label: "CAT FOOD", accent: "#6f6a9c", soft: "#e7e4f3", retail: ["3 kg bag", 620, "₹206.67/kg"], trade: ["25 kg breeder pack", 4400, "₹176/kg"], tags: ["pet food", "cat"] },
    { id: "foil", title: "Food-grade aluminium foil", brand: "Kitchen essentials", category: "kitchen-disposables", businessCategory: "horeca-supplies", label: "FOIL", accent: "#77818c", soft: "#e7ebee", retail: ["25 m roll", 110, "₹4.40/m"], trade: ["Carton of 30 rolls", 2100, "₹70/roll"], tags: ["food wrap", "disposable"] },
    { id: "paper-cups", title: "Food-safe paper cups", brand: "Kitchen essentials", category: "kitchen-disposables", businessCategory: "horeca-supplies", label: "CUPS", accent: "#cc7b34", soft: "#f7e2ce", retail: ["Pack of 50", 125, "₹2.50/cup"], trade: ["Carton of 1,000 cups", 1600, "₹1.60/cup"], tags: ["disposable", "foodservice"] },
    { id: "thermal-rolls", title: "POS thermal paper rolls", brand: "Store essentials", category: "stationery-office", businessCategory: "retail-supplies", label: "POS ROLLS", accent: "#4457a6", soft: "#e2e6f7", retail: ["10 rolls", 170, "₹17/roll"], trade: ["Carton of 200 rolls", 2100, "₹10.50/roll"], tags: ["billing paper", "receipt"] },
    { id: "price-labels", title: "Self-adhesive price labels", brand: "Store essentials", category: "stationery-office", businessCategory: "retail-supplies", label: "LABELS", accent: "#3b8d73", soft: "#dbf0e8", retail: ["10 rolls", 145, "₹14.50/roll"], trade: ["Carton of 200 rolls", 1750, "₹8.75/roll"], tags: ["retail label", "pricing"] },
    { id: "pencils", title: "HB graphite pencils", brand: "Home and school", category: "stationery-office", label: "PENCILS", accent: "#df8a20", soft: "#fbe7c9", retail: ["20 pencils", 120, "₹6/pencil"], trade: ["Carton of 500 pencils", 1900, "₹3.80/pencil"], tags: ["school", "office"] },
  ];

  catalogueRows.push(
    { id: "banana", title: "Fresh bananas", brand: "Farm fresh", category: "fresh-produce", subcategory: "fruits", label: "BANANA", accent: "#dfad1f", soft: "#fff1b8", retail: ["1 kg pack", 58, "₹58/kg"], trade: ["20 kg crate", 820, "₹41/kg"], tags: ["fruit", "kela"] },
    { id: "potato", title: "Fresh potatoes", brand: "Farm fresh", category: "fresh-produce", subcategory: "vegetables", label: "POTATO", accent: "#a8773f", soft: "#f0dfc8", retail: ["2 kg pack", 68, "₹34/kg"], trade: ["25 kg sack", 625, "₹25/kg"], tags: ["vegetable", "aloo"] },
    { id: "curd", title: "Fresh set curd", brand: "Daily dairy", category: "dairy-bakery", subcategory: "milk-curd", label: "CURD", accent: "#3279b8", soft: "#e3f1fc", retail: ["400 g tub", 48, "₹120/kg"], trade: ["Crate of 24 × 400 g", 936, "₹97.50/kg"], tags: ["dahi", "chilled"] },
    { id: "paneer", title: "Fresh malai paneer", brand: "Daily dairy", category: "dairy-bakery", subcategory: "cheese-paneer", label: "PANEER", accent: "#d09c3d", soft: "#fff0cf", retail: ["200 g pack", 92, "₹460/kg"], trade: ["10 kg foodservice pack", 3650, "₹365/kg"], tags: ["cottage cheese", "chilled"] },
    { id: "fish-fillet", title: "Fresh boneless fish fillets", brand: "Cold-chain fresh", category: "meat-eggs", subcategory: "seafood", label: "FISH", accent: "#3186a1", soft: "#dff3f7", retail: ["500 g pack", 310, "₹620/kg"], trade: ["10 kg foodservice pack", 5150, "₹515/kg"], tags: ["seafood", "machli"] },
    { id: "mutton", title: "Fresh mutton curry cut", brand: "Cold-chain fresh", category: "meat-eggs", subcategory: "red-meat", label: "MUTTON", accent: "#a8403e", soft: "#f7dedd", retail: ["500 g pack", 465, "₹930/kg"], trade: ["10 kg foodservice pack", 7900, "₹790/kg"], tags: ["goat meat", "protein"] },
    { id: "toor-dal", title: "Unpolished toor dal", brand: "Daily staples", category: "grains-pulses", subcategory: "pulses", label: "TOOR DAL", accent: "#d69824", soft: "#ffedc4", retail: ["1 kg pack", 168, "₹168/kg"], trade: ["30 kg sack", 4200, "₹140/kg"], tags: ["arhar dal", "pulses"] },
    { id: "sugar", title: "Fine crystal sugar", brand: "Daily staples", category: "grains-pulses", subcategory: "sugar-salt", label: "SUGAR", accent: "#6f78a0", soft: "#eef0f7", retail: ["2 kg pack", 104, "₹52/kg"], trade: ["50 kg sack", 2200, "₹44/kg"], tags: ["chini", "sweetener"] },
    { id: "mustard-oil", title: "Cold-pressed mustard oil", brand: "Kitchen essentials", category: "oils-ghee", subcategory: "traditional-oils", label: "MUSTARD", accent: "#c49b18", soft: "#fff0ae", retail: ["1 L bottle", 188, "₹188/L"], trade: ["Case of 15 × 1 L", 2460, "₹164/L"], tags: ["sarson oil", "cooking oil"] },
    { id: "groundnut-oil", title: "Filtered groundnut oil", brand: "Kitchen essentials", category: "oils-ghee", subcategory: "traditional-oils", label: "GROUNDNUT", accent: "#b57932", soft: "#f6e2c6", retail: ["1 L bottle", 210, "₹210/L"], trade: ["Case of 15 × 1 L", 2790, "₹186/L"], tags: ["peanut oil", "cooking oil"] },
    { id: "red-chilli", title: "Red chilli powder", brand: "Everyday spices", category: "spices-condiments", subcategory: "ground-spices", label: "CHILLI", accent: "#c94335", soft: "#f8dcd8", retail: ["200 g pack", 82, "₹410/kg"], trade: ["10 kg trade pack", 3300, "₹330/kg"], tags: ["lal mirch", "masala"] },
    { id: "coriander-seeds", title: "Whole coriander seeds", brand: "Everyday spices", category: "spices-condiments", subcategory: "whole-spices", label: "DHANIA", accent: "#8c7433", soft: "#eee3c6", retail: ["200 g pack", 64, "₹320/kg"], trade: ["10 kg trade pack", 2450, "₹245/kg"], tags: ["dhania", "whole spice"] },
    { id: "corn-flakes", title: "Crunchy corn flakes", brand: "Morning staples", category: "breakfast-instant", subcategory: "cereals", label: "CORN FLAKES", accent: "#cf8b21", soft: "#ffebc5", retail: ["750 g pack", 215, "₹286.67/kg"], trade: ["Case of 12 × 750 g", 2160, "₹240/kg"], tags: ["breakfast cereal", "corn"] },
    { id: "idli-mix", title: "Ready idli batter mix", brand: "Morning staples", category: "breakfast-instant", subcategory: "instant-mixes", label: "IDLI MIX", accent: "#5d8e45", soft: "#e3efd9", retail: ["1 kg pack", 145, "₹145/kg"], trade: ["Case of 20 × 1 kg", 2380, "₹119/kg"], tags: ["instant breakfast", "south indian"] },
    { id: "ketchup", title: "Classic tomato ketchup", brand: "Meal companions", category: "packaged-foods", subcategory: "sauces-spreads", label: "KETCHUP", accent: "#c84935", soft: "#f8ddd7", retail: ["950 g pouch", 135, "₹142.11/kg"], trade: ["Case of 24 × 950 g", 2640, "₹115.79/kg"], tags: ["tomato sauce", "condiment"] },
    { id: "jam", title: "Mixed fruit jam", brand: "Meal companions", category: "packaged-foods", subcategory: "sauces-spreads", label: "JAM", accent: "#a84b71", soft: "#f6ddea", retail: ["500 g jar", 165, "₹330/kg"], trade: ["Case of 24 × 500 g", 3240, "₹270/kg"], tags: ["fruit spread", "breakfast"] },
    { id: "potato-chips", title: "Salted potato chips", brand: "Tea-time favourites", category: "snacks-confectionery", subcategory: "chips", label: "CHIPS", accent: "#d88924", soft: "#ffe9c4", retail: ["Pack of 6", 120, "₹20/pack"], trade: ["Carton of 120 packs", 1680, "₹14/pack"], tags: ["crisps", "snack"] },
    { id: "chocolate", title: "Milk chocolate bars", brand: "Sweet favourites", category: "snacks-confectionery", subcategory: "chocolates", label: "CHOCOLATE", accent: "#77513d", soft: "#ecdcd3", retail: ["Pack of 6", 210, "₹35/bar"], trade: ["Carton of 144 bars", 3960, "₹27.50/bar"], tags: ["candy", "sweet"] },
    { id: "coffee", title: "Instant coffee", brand: "Daily beverages", category: "beverages", subcategory: "tea-coffee", label: "COFFEE", accent: "#765337", soft: "#ecded2", retail: ["200 g jar", 395, "₹1,975/kg"], trade: ["Case of 24 × 200 g", 7920, "₹1,650/kg"], tags: ["hot drink", "instant coffee"] },
    { id: "water", title: "Packaged drinking water", brand: "Daily beverages", category: "beverages", subcategory: "water", label: "WATER", accent: "#3489bd", soft: "#dff1fa", retail: ["Pack of 12 × 1 L", 180, "₹15/L"], trade: ["Pallet of 60 packs", 8100, "₹11.25/L"], tags: ["mineral water", "bottled water"] },
    { id: "frozen-fries", title: "Frozen potato fries", brand: "Frozen favourites", category: "frozen-chilled", subcategory: "frozen-snacks", label: "FRIES", accent: "#d79b25", soft: "#ffedc4", retail: ["1 kg pack", 225, "₹225/kg"], trade: ["20 kg foodservice case", 3800, "₹190/kg"], tags: ["french fries", "frozen snack"] },
    { id: "cheese-slices", title: "Processed cheese slices", brand: "Chilled favourites", category: "frozen-chilled", subcategory: "cheese-butter", label: "CHEESE", accent: "#d7a328", soft: "#fff0bf", retail: ["400 g pack", 285, "₹712.50/kg"], trade: ["Case of 20 × 400 g", 4700, "₹587.50/kg"], tags: ["cheese", "chilled dairy"] },
    { id: "toothbrush", title: "Soft family toothbrushes", brand: "Personal care", category: "personal-care", subcategory: "oral-care", label: "BRUSH", accent: "#357cb1", soft: "#e0effa", retail: ["Pack of 4", 140, "₹35/brush"], trade: ["Carton of 96 brushes", 2400, "₹25/brush"], tags: ["oral care", "dental"] },
    { id: "handwash", title: "Gentle liquid handwash", brand: "Personal care", category: "personal-care", subcategory: "hand-care", label: "HANDWASH", accent: "#348c86", soft: "#dbf1ed", retail: ["750 ml refill", 135, "₹180/L"], trade: ["Case of 24 refills", 2520, "₹140/L"], tags: ["hand care", "soap refill"] },
    { id: "moisturizer", title: "Daily skin moisturizer", brand: "Beauty & grooming", category: "beauty-grooming", subcategory: "skin-care", label: "MOISTURE", accent: "#b16494", soft: "#f3dfed", retail: ["200 ml bottle", 245, "₹1.23/ml"], trade: ["Case of 24 bottles", 4680, "₹195/bottle"], tags: ["skin care", "lotion"] },
    { id: "hair-oil", title: "Nourishing coconut hair oil", brand: "Beauty & grooming", category: "beauty-grooming", subcategory: "hair-care", label: "HAIR OIL", accent: "#4b8a51", soft: "#dff0df", retail: ["500 ml bottle", 195, "₹390/L"], trade: ["Case of 24 bottles", 3720, "₹155/bottle"], tags: ["hair care", "coconut oil"] },
    { id: "garbage-bags", title: "Strong garbage bags", brand: "Home essentials", category: "home-care", subcategory: "waste-care", label: "BAGS", accent: "#4b6572", soft: "#e1e8ec", retail: ["Pack of 30", 145, "₹4.83/bag"], trade: ["Carton of 1,200 bags", 3960, "₹3.30/bag"], tags: ["waste bags", "bin liner"] },
    { id: "air-freshener", title: "Long-lasting air freshener", brand: "Home essentials", category: "home-care", subcategory: "air-care", label: "AIR CARE", accent: "#4b83a8", soft: "#deedf5", retail: ["240 ml can", 185, "₹0.77/ml"], trade: ["Case of 24 cans", 3480, "₹145/can"], tags: ["room freshener", "fragrance"] },
    { id: "fabric-conditioner", title: "Fresh fabric conditioner", brand: "Laundry care", category: "laundry-cleaning", subcategory: "laundry", label: "FABRIC", accent: "#6c68b0", soft: "#e8e5f7", retail: ["2 L bottle", 320, "₹160/L"], trade: ["Case of 12 × 2 L", 3120, "₹130/L"], tags: ["fabric softener", "laundry"] },
    { id: "liquid-detergent", title: "Liquid laundry detergent", brand: "Laundry care", category: "laundry-cleaning", subcategory: "laundry", label: "LIQUID", accent: "#2e76b6", soft: "#dfedfa", retail: ["2 L bottle", 295, "₹147.50/L"], trade: ["20 L institutional can", 2360, "₹118/L"], tags: ["washing liquid", "laundry"] },
    { id: "baby-lotion", title: "Gentle baby lotion", brand: "Baby care", category: "baby-care", subcategory: "baby-skin", label: "BABY LOTION", accent: "#d483a0", soft: "#f8e2ea", retail: ["400 ml bottle", 285, "₹0.71/ml"], trade: ["Case of 24 bottles", 5400, "₹225/bottle"], tags: ["baby skin", "infant care"] },
    { id: "baby-cereal", title: "Rice and milk baby cereal", brand: "Baby nutrition", category: "baby-care", subcategory: "baby-nutrition", label: "CEREAL", accent: "#d39a35", soft: "#f9e8c9", retail: ["300 g pack", 245, "₹816.67/kg"], trade: ["Case of 24 packs", 4680, "₹650/kg"], tags: ["infant food", "baby nutrition"] },
    { id: "glucose", title: "Instant energy glucose", brand: "Daily wellness", category: "health-wellness", subcategory: "energy-hydration", label: "GLUCOSE", accent: "#e19222", soft: "#ffebc5", retail: ["1 kg pack", 165, "₹165/kg"], trade: ["Case of 20 × 1 kg", 2700, "₹135/kg"], tags: ["energy drink", "hydration"] },
    { id: "sanitary-pads", title: "Ultra-soft sanitary pads", brand: "Daily wellness", category: "health-wellness", subcategory: "personal-wellness", label: "CARE", accent: "#b8669d", soft: "#f3e0ee", retail: ["Pack of 30", 285, "₹9.50/pad"], trade: ["Case of 24 packs", 5640, "₹7.83/pad"], tags: ["period care", "women wellness"] },
    { id: "dog-treats", title: "Chicken dog treats", brand: "Pet nutrition", category: "pet-care", subcategory: "dog-care", label: "TREATS", accent: "#a46c38", soft: "#f1dfcd", retail: ["500 g pack", 245, "₹490/kg"], trade: ["Case of 24 packs", 4680, "₹390/kg"], tags: ["dog snack", "pet treat"] },
    { id: "cat-litter", title: "Clumping cat litter", brand: "Pet hygiene", category: "pet-care", subcategory: "pet-hygiene", label: "LITTER", accent: "#68708c", soft: "#e5e7ef", retail: ["5 kg bag", 425, "₹85/kg"], trade: ["25 kg breeder pack", 1750, "₹70/kg"], tags: ["cat hygiene", "pet care"] },
    { id: "tissues", title: "Food-safe paper tissues", brand: "Kitchen essentials", category: "kitchen-disposables", businessCategory: "horeca-supplies", subcategory: "paper-hygiene", label: "TISSUES", accent: "#557a9a", soft: "#e1edf5", retail: ["Pack of 200", 85, "₹0.43/tissue"], trade: ["Carton of 8,000 tissues", 2320, "₹0.29/tissue"], tags: ["napkin", "foodservice"] },
    { id: "takeaway-containers", title: "Food-safe takeaway containers", brand: "Kitchen essentials", category: "kitchen-disposables", businessCategory: "horeca-supplies", subcategory: "takeaway-packaging", label: "CONTAINER", accent: "#5d8168", soft: "#e2eee5", retail: ["Pack of 25", 175, "₹7/container"], trade: ["Carton of 1,000", 4300, "₹4.30/container"], tags: ["food box", "delivery packaging"] },
    { id: "barcode-labels", title: "Barcode label rolls", brand: "Store essentials", category: "stationery-office", businessCategory: "retail-supplies", subcategory: "shop-supplies", businessSubcategory: "pricing-labels", label: "BARCODE", accent: "#3f7292", soft: "#e0ecf3", retail: ["10 rolls", 260, "₹26/roll"], trade: ["Carton of 200 rolls", 3600, "₹18/roll"], tags: ["barcode sticker", "retail label"] },
    { id: "carry-bags", title: "Reusable retail carry bags", brand: "Store essentials", category: "kitchen-disposables", businessCategory: "retail-supplies", subcategory: "retail-packaging", businessSubcategory: "retail-packaging", label: "CARRY BAG", accent: "#4d8765", soft: "#e1efe7", retail: ["Pack of 25", 220, "₹8.80/bag"], trade: ["Carton of 1,000 bags", 5400, "₹5.40/bag"], tags: ["shopping bag", "retail packaging"] },
    { id: "printer-paper", title: "A4 copier paper", brand: "Office essentials", category: "stationery-office", subcategory: "printing-paper", label: "A4 PAPER", accent: "#5369a3", soft: "#e4e8f5", retail: ["Ream of 500 sheets", 295, "₹0.59/sheet"], trade: ["Carton of 10 reams", 2460, "₹246/ream"], tags: ["printer paper", "office paper"] },
    { id: "ball-pens", title: "Smooth blue ball pens", brand: "Office essentials", category: "stationery-office", subcategory: "writing", label: "PENS", accent: "#315fa3", soft: "#dfe9f7", retail: ["Pack of 20", 140, "₹7/pen"], trade: ["Carton of 1,000 pens", 4200, "₹4.20/pen"], tags: ["writing", "office pen"] },
  );

  const largerRetailPack = (pack) => {
    const packOf = pack.match(/pack of\s+(\d+)/i);
    if (packOf) return pack.replace(packOf[1], String(Number(packOf[1]) * 2));
    const quantity = pack.match(/^(\d+(?:\.\d+)?)\s*(kg|g|l|ml|m|eggs|diapers|wipes|rolls|pencils)\b/i);
    if (quantity) {
      const doubled = Number(quantity[1]) * 2;
      return pack.replace(quantity[1], Number.isInteger(doubled) ? String(doubled) : doubled.toFixed(1));
    }
    return `Value pack · ${pack}`;
  };

  const protectionFor = (category) => {
    if (category === "fresh-produce") return "Quality refund available for an eligible issue reported within 24 hours.";
    if (category === "meat-eggs" || category === "frozen-chilled") {
      return "Cold-chain or quality issues can be reported immediately after delivery.";
    }
    return "Unopened or transit-damaged packs are covered by the return terms shown before payment.";
  };

  const catalogueProducts = catalogueRows.map((row, index) => {
    const businessCategory = row.businessCategory || row.category;
    const retailPartner = commercePartners[row.category] || commercePartners["stationery-office"];
    const tradePartner = commercePartners[businessCategory] || retailPartner;
    const retailAltPrice = Math.round(row.retail[1] * 1.92);
    const tradeMidPrice = Math.round(row.trade[1] * 0.97);
    const tradeBestPrice = Math.round(row.trade[1] * 0.93);
    art[row.id] = packagedArt(row.label, row.accent, row.soft);

    return {
      id: row.id,
      title: row.title,
      brand: row.brand,
      category: row.category,
      businessCategory,
      subcategory: row.subcategory || existingProductSubcategories[row.id]?.[0],
      businessSubcategory:
        row.businessSubcategory ||
        existingProductSubcategories[row.id]?.[1] ||
        row.subcategory ||
        existingProductSubcategories[row.id]?.[0],
      tags: row.tags,
      visual: row.id,
      colors: [row.soft, "#f4f5fb"],
      protection: protectionFor(row.category),
      personal: {
        pack: row.retail[0],
        price: row.retail[1],
        unit: row.retail[2],
        badge: index % 3 === 0 ? "Lowest delivered price" : index % 3 === 1 ? "Best value" : "Popular nearby",
        stock: index % 5 === 0 ? "Only 6 left" : "In stock",
        seller: retailPartner[0],
        sellerType: "Verified retailer",
        delivery: index % 2 === 0 ? "18 minutes" : "Today by 7:30 pm",
        location: `${(1.1 + (index % 6) * 0.4).toFixed(1)} km away`,
        returnTerm: "Eligibility and return window shown before payment",
        packs: [
          [row.retail[0], money(row.retail[1])],
          [largerRetailPack(row.retail[0]), money(retailAltPrice)],
        ],
        sellers: [
          ["NP", retailPartner[0], "Verified retailer · nearby", row.retail[1], "Best available price"],
          ["JM", "Jodhpur City Mart", "Verified retailer · today", Math.round(row.retail[1] * 1.04), "Alternate nearby seller"],
        ],
      },
      business: {
        pack: row.trade[0],
        price: row.trade[1],
        unit: row.trade[2],
        badge: index % 2 === 0 ? "Best landed cost" : "Trade price",
        stock: `${12 + (index % 8) * 6} trade packs available`,
        seller: tradePartner[1],
        sellerType: tradePartner[2],
        delivery: index % 2 === 0 ? "Dispatch within one day" : "Delivery within two days",
        location: "Delivered to 342003",
        returnTerm: "Transit or quality claim within the stated inspection window",
        packs: [
          [row.trade[0], "MOQ 2"],
          [`2 × ${row.trade[0]}`, "MOQ 1"],
        ],
        breaks: [
          ["2–4 trade packs", money(row.trade[1])],
          ["5–9 trade packs", money(tradeMidPrice)],
          ["10+ trade packs", money(tradeBestPrice)],
        ],
        terms: [
          ["Tax", "Shown on GST invoice"],
          ["Freight", "Included above order threshold"],
          ["Payment", "UPI or bank transfer"],
          ["Credit", index % 3 === 0 ? "7 days · approved" : "Available after approval"],
        ],
        sellers: [
          ["TP", tradePartner[1], `${tradePartner[2]} · committed dispatch`, row.trade[1], "Best landed cost"],
          ["RT", "Rajasthan Trade Network", "Verified wholesaler · two days", Math.round(row.trade[1] * 1.03), "Flexible fulfilment"],
        ],
      },
    };
  });

  products.push(...catalogueProducts);
  products.forEach((product) => {
    const assigned = existingProductSubcategories[product.id];
    if (!product.subcategory && assigned) product.subcategory = assigned[0];
    if (!product.businessSubcategory && assigned) {
      product.businessSubcategory = assigned[1] || assigned[0];
    }
  });

  const sharedPrimaryCategoryBySubcategory = {
    fruits: "fruits-vegetables",
    vegetables: "fruits-vegetables",
    "milk-curd": "dairy-bakery",
    "cheese-paneer": "dairy-bakery",
    "bread-bakery": "dairy-bakery",
    eggs: "eggs-poultry",
    poultry: "eggs-poultry",
    seafood: "meat-seafood",
    "red-meat": "meat-seafood",
    flour: "flour-rice-grains",
    rice: "flour-rice-grains",
    pulses: "dals-staples",
    "sugar-salt": "dals-staples",
    "edible-oils": "oils-ghee",
    ghee: "oils-ghee",
    "traditional-oils": "oils-ghee",
    "ground-spices": "ground-spices",
    "whole-spices": "whole-spices",
    "traditional-breakfast": "breakfast-cereals",
    cereals: "breakfast-cereals",
    "instant-mixes": "instant-foods",
    "noodles-pasta": "instant-foods",
    "sauces-spreads": "sauces-spreads",
    biscuits: "biscuits-chocolate",
    chocolates: "biscuits-chocolate",
    savouries: "namkeen-chips",
    chips: "namkeen-chips",
    "tea-coffee": "tea-coffee",
    juices: "juices-water",
    water: "juices-water",
    "frozen-veg": "frozen-foods",
    "frozen-snacks": "frozen-foods",
    "dairy-desserts": "icecream-cheese",
    "cheese-butter": "icecream-cheese",
    "bath-body": "bath-hand-care",
    "hand-care": "bath-hand-care",
    "oral-care": "oral-care",
    "hair-care": "hair-care",
    "skin-care": "skin-care",
    "floor-bathroom": "surface-cleaners",
    "waste-care": "air-waste-care",
    "air-care": "air-waste-care",
    laundry: "laundry-dishwash",
    "dish-care": "laundry-dishwash",
    "diapers-wipes": "diapers-wipes",
    "baby-skin": "baby-care",
    "baby-nutrition": "baby-care",
    "herbal-wellness": "health-wellness",
    nutrition: "health-wellness",
    "energy-hydration": "health-wellness",
    "personal-wellness": "health-wellness",
    "dog-care": "dog-care",
    "cat-care": "cat-care",
    "pet-hygiene": "cat-care",
  };

  const retailPrimaryCategoryBySubcategory = {
    ...sharedPrimaryCategoryBySubcategory,
    "food-storage": "food-storage-packs",
    "takeaway-packaging": "food-storage-packs",
    "retail-packaging": "food-storage-packs",
    tableware: "cups-tissues",
    "paper-hygiene": "cups-tissues",
    notebooks: "school-office",
    writing: "school-office",
    "printing-paper": "school-office",
    "shop-supplies": "shop-supplies",
  };

  const wholesalePrimaryCategoryBySubcategory = {
    ...sharedPrimaryCategoryBySubcategory,
    "food-storage": "horeca-food-packs",
    "takeaway-packaging": "horeca-food-packs",
    tableware: "horeca-tableware",
    "paper-hygiene": "horeca-tableware",
    "pos-consumables": "retail-supplies",
    "pricing-labels": "retail-supplies",
    "retail-packaging": "retail-supplies",
    notebooks: "stationery-office",
    writing: "stationery-office",
    "printing-paper": "stationery-office",
  };

  products.forEach((product) => {
    product.category = retailPrimaryCategoryBySubcategory[product.subcategory];
    product.businessCategory = wholesalePrimaryCategoryBySubcategory[product.businessSubcategory];
  });

  const categorySets = {
    personal: [
      { id: "all", label: "For you", glyph: "✦" },
      { id: "fruits-vegetables", label: "Fruits & vegetables", glyph: "●" },
      { id: "dairy-bakery", label: "Dairy & bakery", glyph: "◒" },
      { id: "eggs-poultry", label: "Eggs & poultry", glyph: "◉" },
      { id: "meat-seafood", label: "Meat & seafood", glyph: "◍" },
      { id: "flour-rice-grains", label: "Flour, rice & grains", glyph: "◇" },
      { id: "dals-staples", label: "Dals & staples", glyph: "◆" },
      { id: "oils-ghee", label: "Oil & ghee", glyph: "◐" },
      { id: "ground-spices", label: "Ground spices", glyph: "✧" },
      { id: "whole-spices", label: "Whole spices", glyph: "✣" },
      { id: "breakfast-cereals", label: "Breakfast & cereals", glyph: "☀" },
      { id: "instant-foods", label: "Instant foods", glyph: "▣" },
      { id: "sauces-spreads", label: "Sauces & spreads", glyph: "◈" },
      { id: "biscuits-chocolate", label: "Biscuits & chocolate", glyph: "○" },
      { id: "namkeen-chips", label: "Namkeen & chips", glyph: "◌" },
      { id: "tea-coffee", label: "Tea & coffee", glyph: "◫" },
      { id: "juices-water", label: "Juices & water", glyph: "◧" },
      { id: "frozen-foods", label: "Frozen foods", glyph: "❄" },
      { id: "icecream-cheese", label: "Ice cream & cheese", glyph: "◓" },
      { id: "bath-hand-care", label: "Bath & hand care", glyph: "✚" },
      { id: "oral-care", label: "Oral care", glyph: "⌁" },
      { id: "hair-care", label: "Hair care", glyph: "♢" },
      { id: "skin-care", label: "Skin care", glyph: "◊" },
      { id: "surface-cleaners", label: "Surface cleaners", glyph: "⌂" },
      { id: "air-waste-care", label: "Air & waste care", glyph: "◎" },
      { id: "laundry-dishwash", label: "Laundry & dishwash", glyph: "≋" },
      { id: "diapers-wipes", label: "Diapers & wipes", glyph: "◉" },
      { id: "baby-care", label: "Baby care", glyph: "◎" },
      { id: "health-wellness", label: "Health & wellness", glyph: "＋" },
      { id: "medicine", label: "Medicine", glyph: "✚", view: "medicine" },
      { id: "dog-care", label: "Dog care", glyph: "♡" },
      { id: "cat-care", label: "Cat care", glyph: "♧" },
      { id: "food-storage-packs", label: "Food storage & packs", glyph: "▤" },
      { id: "cups-tissues", label: "Cups & tissues", glyph: "◒" },
      { id: "school-office", label: "School & office", glyph: "□" },
      { id: "shop-supplies", label: "Shop supplies", glyph: "▦" },
    ],
    business: [
      { id: "all", label: "Best prices", glyph: "✦" },
      { id: "retail-supplies", label: "Retail supplies", glyph: "▦" },
      { id: "horeca-food-packs", label: "HoReCa food packs", glyph: "▤" },
      { id: "horeca-tableware", label: "HoReCa tableware", glyph: "◒" },
      { id: "stationery-office", label: "Stationery & office", glyph: "□" },
      { id: "fruits-vegetables", label: "Fruits & vegetables", glyph: "●" },
      { id: "dairy-bakery", label: "Dairy & bakery", glyph: "◒" },
      { id: "eggs-poultry", label: "Eggs & poultry", glyph: "◉" },
      { id: "meat-seafood", label: "Meat & seafood", glyph: "◍" },
      { id: "flour-rice-grains", label: "Flour, rice & grains", glyph: "◇" },
      { id: "dals-staples", label: "Dals & staples", glyph: "◆" },
      { id: "oils-ghee", label: "Oils & ghee", glyph: "◐" },
      { id: "ground-spices", label: "Ground spices", glyph: "✧" },
      { id: "whole-spices", label: "Whole spices", glyph: "✣" },
      { id: "breakfast-cereals", label: "Breakfast & cereals", glyph: "☀" },
      { id: "instant-foods", label: "Instant foods", glyph: "▣" },
      { id: "sauces-spreads", label: "Sauces & spreads", glyph: "◈" },
      { id: "biscuits-chocolate", label: "Biscuits & chocolate", glyph: "○" },
      { id: "namkeen-chips", label: "Namkeen & chips", glyph: "◌" },
      { id: "tea-coffee", label: "Tea & coffee", glyph: "◫" },
      { id: "juices-water", label: "Juices & water", glyph: "◧" },
      { id: "frozen-foods", label: "Frozen foods", glyph: "❄" },
      { id: "icecream-cheese", label: "Ice cream & cheese", glyph: "◓" },
      { id: "bath-hand-care", label: "Bath & hand care", glyph: "✚" },
      { id: "oral-care", label: "Oral care", glyph: "⌁" },
      { id: "hair-care", label: "Hair care", glyph: "♢" },
      { id: "skin-care", label: "Skin care", glyph: "◊" },
      { id: "surface-cleaners", label: "Surface cleaners", glyph: "⌂" },
      { id: "air-waste-care", label: "Air & waste care", glyph: "◎" },
      { id: "laundry-dishwash", label: "Laundry & dishwash", glyph: "≋" },
      { id: "diapers-wipes", label: "Diapers & wipes", glyph: "◉" },
      { id: "baby-care", label: "Baby care", glyph: "◎" },
      { id: "health-wellness", label: "Health & wellness", glyph: "＋" },
      { id: "medicine", label: "Medicine", glyph: "✚", view: "medicine" },
      { id: "dog-care", label: "Dog care", glyph: "♡" },
      { id: "cat-care", label: "Cat care", glyph: "♧" },
    ],
  };

  const subcategoryLabels = {
    fruits: "Fruits",
    vegetables: "Vegetables",
    "milk-curd": "Milk & curd",
    "cheese-paneer": "Cheese & paneer",
    "bread-bakery": "Bread & bakery",
    eggs: "Eggs",
    poultry: "Poultry",
    seafood: "Seafood",
    "red-meat": "Mutton & meat",
    flour: "Flour",
    rice: "Rice",
    pulses: "Pulses",
    "sugar-salt": "Sugar & salt",
    "edible-oils": "Edible oils",
    ghee: "Ghee",
    "traditional-oils": "Traditional oils",
    "ground-spices": "Ground spices",
    "whole-spices": "Whole spices",
    "traditional-breakfast": "Indian breakfast",
    cereals: "Cereals",
    "instant-mixes": "Instant mixes",
    "noodles-pasta": "Noodles & pasta",
    "sauces-spreads": "Sauces & spreads",
    biscuits: "Biscuits",
    savouries: "Namkeen",
    chips: "Chips",
    chocolates: "Chocolates",
    "tea-coffee": "Tea & coffee",
    juices: "Juices",
    water: "Water",
    "frozen-veg": "Frozen vegetables",
    "frozen-snacks": "Frozen snacks",
    "dairy-desserts": "Ice cream",
    "cheese-butter": "Cheese & butter",
    "bath-body": "Bath & body",
    "oral-care": "Oral care",
    "hand-care": "Hand care",
    "hair-care": "Hair care",
    "skin-care": "Skin care",
    "floor-bathroom": "Floor & bathroom",
    "waste-care": "Waste care",
    "air-care": "Air care",
    laundry: "Laundry",
    "dish-care": "Dish care",
    "diapers-wipes": "Diapers & wipes",
    "baby-skin": "Baby skin care",
    "baby-nutrition": "Baby nutrition",
    "herbal-wellness": "Herbal wellness",
    nutrition: "Nutrition",
    "energy-hydration": "Energy & hydration",
    "personal-wellness": "Personal wellness",
    "dog-care": "Dog care",
    "cat-care": "Cat care",
    "pet-hygiene": "Pet hygiene",
    "food-storage": "Food storage",
    tableware: "Cups & tableware",
    "paper-hygiene": "Tissues & napkins",
    "takeaway-packaging": "Takeaway packs",
    "retail-packaging": "Retail packaging",
    notebooks: "Notebooks",
    writing: "Writing",
    "shop-supplies": "Shop supplies",
    "printing-paper": "Printing paper",
    "pos-consumables": "POS consumables",
    "pricing-labels": "Labels & pricing",
  };

  const sharedSubcategorySets = {
    "fruits-vegetables": ["fruits", "vegetables"],
    "dairy-bakery": ["milk-curd", "cheese-paneer", "bread-bakery"],
    "eggs-poultry": ["eggs", "poultry"],
    "meat-seafood": ["seafood", "red-meat"],
    "flour-rice-grains": ["flour", "rice"],
    "dals-staples": ["pulses", "sugar-salt"],
    "oils-ghee": ["edible-oils", "ghee", "traditional-oils"],
    "ground-spices": ["ground-spices"],
    "whole-spices": ["whole-spices"],
    "breakfast-cereals": ["traditional-breakfast", "cereals"],
    "instant-foods": ["instant-mixes", "noodles-pasta"],
    "sauces-spreads": ["sauces-spreads"],
    "biscuits-chocolate": ["biscuits", "chocolates"],
    "namkeen-chips": ["savouries", "chips"],
    "tea-coffee": ["tea-coffee"],
    "juices-water": ["juices", "water"],
    "frozen-foods": ["frozen-veg", "frozen-snacks"],
    "icecream-cheese": ["dairy-desserts", "cheese-butter"],
    "bath-hand-care": ["bath-body", "hand-care"],
    "oral-care": ["oral-care"],
    "hair-care": ["hair-care"],
    "skin-care": ["skin-care"],
    "surface-cleaners": ["floor-bathroom"],
    "air-waste-care": ["waste-care", "air-care"],
    "laundry-dishwash": ["laundry", "dish-care"],
    "diapers-wipes": ["diapers-wipes"],
    "baby-care": ["baby-skin", "baby-nutrition"],
    "health-wellness": ["herbal-wellness", "nutrition", "energy-hydration", "personal-wellness"],
    "dog-care": ["dog-care"],
    "cat-care": ["cat-care", "pet-hygiene"],
  };

  const subcategorySets = {
    personal: {
      ...sharedSubcategorySets,
      "food-storage-packs": ["food-storage", "takeaway-packaging", "retail-packaging"],
      "cups-tissues": ["tableware", "paper-hygiene"],
      "school-office": ["notebooks", "writing", "printing-paper"],
      "shop-supplies": ["shop-supplies"],
    },
    business: {
      ...sharedSubcategorySets,
      "horeca-food-packs": ["food-storage", "takeaway-packaging"],
      "horeca-tableware": ["tableware", "paper-hygiene"],
      "retail-supplies": ["pos-consumables", "pricing-labels", "retail-packaging"],
      "stationery-office": ["notebooks", "writing", "printing-paper"],
    },
  };

  const intentionalContextMappings = {
    foil: ["food-storage-packs", "horeca-food-packs"],
    "takeaway-containers": ["food-storage-packs", "horeca-food-packs"],
    "paper-cups": ["cups-tissues", "horeca-tableware"],
    tissues: ["cups-tissues", "horeca-tableware"],
    "thermal-rolls": ["shop-supplies", "retail-supplies"],
    "price-labels": ["shop-supplies", "retail-supplies"],
    "barcode-labels": ["shop-supplies", "retail-supplies"],
    "carry-bags": ["food-storage-packs", "retail-supplies"],
    notebook: ["school-office", "stationery-office"],
    pencils: ["school-office", "stationery-office"],
    "printer-paper": ["school-office", "stationery-office"],
    "ball-pens": ["school-office", "stationery-office"],
  };

  const duplicateProductIds = products
    .map((product) => product.id)
    .filter((id, index, ids) => ids.indexOf(id) !== index);
  if (duplicateProductIds.length) {
    throw new Error(`Buy catalogue has duplicate product identities: ${[...new Set(duplicateProductIds)].join(", ")}`);
  }

  const taxonomyConflicts = products.flatMap((product) => {
    const conflicts = [];
    const retailCategories = new Set(categorySets.personal.filter((category) => !category.view).map((category) => category.id));
    const wholesaleCategories = new Set(categorySets.business.filter((category) => !category.view).map((category) => category.id));
    if (!retailCategories.has(product.category)) conflicts.push(`${product.id}:retail-category:${product.category}`);
    if (!wholesaleCategories.has(product.businessCategory)) conflicts.push(`${product.id}:wholesale-category:${product.businessCategory}`);
    if (!subcategorySets.personal[product.category]?.includes(product.subcategory)) {
      conflicts.push(`${product.id}:retail-subcategory:${product.subcategory || "missing"}`);
    }
    if (!subcategorySets.business[product.businessCategory]?.includes(product.businessSubcategory)) {
      conflicts.push(`${product.id}:wholesale-subcategory:${product.businessSubcategory || "missing"}`);
    }
    if (product.category !== product.businessCategory) {
      const expected = intentionalContextMappings[product.id];
      if (!expected || expected[0] !== product.category || expected[1] !== product.businessCategory) {
        conflicts.push(`${product.id}:unapproved-context-mapping`);
      }
    }
    return conflicts;
  });
  if (taxonomyConflicts.length) {
    throw new Error(`Buy catalogue taxonomy conflict: ${taxonomyConflicts.join(", ")}`);
  }

  const catalogueCoverage = Object.fromEntries(
    ["personal", "business"].map((context) => [
      context,
      categorySets[context]
        .filter((category) => category.id !== "all" && !category.view)
        .map((category) => ({
          id: category.id,
          count: products.filter((product) =>
            (context === "business" ? product.businessCategory : product.category) === category.id
          ).length,
        })),
    ]),
  );
  const incompleteCatalogueCategories = Object.entries(catalogueCoverage)
    .flatMap(([context, categories]) =>
      categories
        .filter((category) => category.count < 2)
        .map((category) => `${context}:${category.id}:${category.count}`),
    );
  if (incompleteCatalogueCategories.length) {
    throw new Error(`Buy catalogue coverage is incomplete: ${incompleteCatalogueCategories.join(", ")}`);
  }

  const categoryAssignmentConflicts = Object.entries(catalogueCoverage).flatMap(([context, categories]) => {
    const assignedIds = categories.flatMap((category) =>
      products
        .filter((product) =>
          (context === "business" ? product.businessCategory : product.category) === category.id
        )
        .map((product) => product.id)
    );
    const duplicateAssignments = assignedIds.filter((id, index, ids) => ids.indexOf(id) !== index);
    const missingAssignments = products
      .map((product) => product.id)
      .filter((id) => !assignedIds.includes(id));
    return [
      ...[...new Set(duplicateAssignments)].map((id) => `${context}:duplicate:${id}`),
      ...missingAssignments.map((id) => `${context}:missing:${id}`),
    ];
  });
  if (categoryAssignmentConflicts.length) {
    throw new Error(`Buy catalogue category assignment conflict: ${categoryAssignmentConflicts.join(", ")}`);
  }

  const emptySubcategories = Object.entries(subcategorySets).flatMap(([context, categories]) =>
    Object.entries(categories).flatMap(([category, subcategories]) =>
      subcategories
        .filter((subcategory) =>
          !products.some((product) =>
            (context === "business" ? product.businessCategory : product.category) === category &&
            (context === "business" ? product.businessSubcategory : product.subcategory) === subcategory
          )
        )
        .map((subcategory) => `${context}:${category}:${subcategory}`)
    )
  );
  if (emptySubcategories.length) {
    throw new Error(`Buy catalogue has empty subcategories: ${emptySubcategories.join(", ")}`);
  }

  app.dataset.catalogueProducts = String(products.length);
  app.dataset.catalogueIdentityConflicts = "0";
  app.dataset.catalogueTaxonomyConflicts = "0";
  app.dataset.catalogueEmptySubcategories = "0";
  app.dataset.retailDuplicateAssignments = "0";
  app.dataset.wholesaleDuplicateAssignments = "0";
  app.dataset.retailMainCategoryCount = String(catalogueCoverage.personal.length);
  app.dataset.wholesaleMainCategoryCount = String(catalogueCoverage.business.length);
  app.dataset.retailCategoryMinimum = String(
    Math.min(...catalogueCoverage.personal.map((category) => category.count)),
  );
  app.dataset.wholesaleCategoryMinimum = String(
    Math.min(...catalogueCoverage.business.map((category) => category.count)),
  );

  const variantOverrides = {
    tomato: "Red ripe · Grade A",
    atta: "Whole wheat · stone-ground",
    oil: "Refined sunflower · food-grade",
    rice: "Aged basmati · premium grain",
    soap: "Herbal · family care",
    notebook: "A4 · ruled pages",
    banana: "Naturally ripened · Grade A",
    potato: "Fresh table potato · Grade A",
    curd: "Plain set curd · chilled",
    paneer: "Malai paneer · chilled",
    "fish-fillet": "Boneless fillet · chilled",
    mutton: "Curry cut · chilled",
    "toor-dal": "Unpolished · premium grain",
    "mustard-oil": "Cold-pressed · filtered",
    "groundnut-oil": "Filtered · food-grade",
    "red-chilli": "Fine ground · pure spice",
    "coriander-seeds": "Whole seed · cleaned",
    "thermal-rolls": "BPA-free · retail POS",
    "barcode-labels": "Self-adhesive · retail grade",
    "carry-bags": "Reusable · reinforced handle",
    "printer-paper": "A4 · 75 GSM",
    "ball-pens": "Blue ink · smooth tip",
  };

  const toTitleCase = (value) =>
    String(value || "")
      .replace(/[-_]+/g, " ")
      .replace(/\b\w/g, (letter) => letter.toUpperCase());

  const productVariant = (product) => {
    if (variantOverrides[product.id]) return variantOverrides[product.id];
    const descriptor = toTitleCase(product.tags?.[0] || product.subcategory || product.brand);
    const category = product.category;
    const quality =
      ["fresh-produce", "dairy-bakery", "meat-eggs", "frozen-chilled"].includes(category)
        ? "quality checked"
        : ["kitchen-disposables", "retail-supplies", "stationery-office"].includes(category)
          ? "commercial grade"
          : "sealed pack";
    return `${descriptor} · ${quality}`;
  };

  const reviewSeed = new URLSearchParams(window.location.search).get("seed");

  const state = {
    context: "personal",
    discovery: {
      personal: {
        category: "all",
        subcategory: "all",
        search: "",
      },
      business: {
        category: "all",
        subcategory: "all",
        search: "",
      },
    },
    categoryRailExpanded: {
      personal: false,
      business: false,
    },
    catalogueScroll: {
      personal: 0,
      business: 0,
    },
    filters: {
      personal: {
        timing: "anytime",
        price: "",
        term: "",
      },
      business: {
        timing: "anytime",
        price: "",
        term: "",
      },
      medicine: {
        timing: "anytime",
        price: "",
        term: "",
      },
    },
    filterSurface: "personal",
    currentProduct: products[0],
    quantity: 1,
    selectedPack: 0,
    householdBasketMembers: {
      "monthly-home": 4,
    },
    householdBasketExpanded: false,
    cartScope: "shop",
    cartReturnView: "retail",
    cartNoticeName: "",
    lastConfirmationScope: "shop",
    ordersTab: "active",
    activeOrderId: "retail-active",
    liveOrderId: "retail-active",
    medicineCategory: "all",
    medicineCategoryRailExpanded: false,
    prescriptionState: "none",
    prescriptionProduct: null,
    selectedSavedPrescription: null,
    prescriptionMatchedProductIds: new Set(),
    rxApprovedProductIds: new Set(),
    pharmacistState: "available",
    refillState: "due",
    payment: "upi",
    addressContext: "personal",
    editingAddressId: null,
    addressDraftLabel: "Other place",
    addressDraft: null,
    selectedMapPlace: {
      addressLine: "Residency Road, Sardarpura",
      landmark: "Near Sardarpura Circle",
      area: "Sardarpura",
      pin: "342003",
      mapsLink: "https://maps.google.com/?q=Sardarpura%2C%20Jodhpur%20342003",
    },
    addressConfirmationKey: null,
    returnToAddressConfirmation: false,
    requestedRecipientName: "",
    requestedRecipientPhone: "",
    sellerChoices: {
      personal: new Map(),
      business: new Map(),
    },
    selectedAddressIds: {
      personal: "home",
      business: "work",
    },
    addressBook: {
      personal: [
        {
          id: "home",
          label: "Home",
          recipient: "Dharmendra Choudhary",
          phone: "+91 92518 93684",
          addressLine: "Residency Road, Sardarpura",
          landmark: "Near Sardarpura Circle",
          area: "Sardarpura · 342003",
          address: "Home · Sardarpura",
          detail: "Sardarpura, Jodhpur, Rajasthan 342003",
        },
        {
          id: "work",
          label: "Work",
          recipient: "Dharmendra Choudhary",
          phone: "+91 92518 93684",
          addressLine: "Ratanada Main Road",
          landmark: "Near Ratanada Circle",
          area: "Ratanada · 342011",
          address: "Work · Ratanada",
          detail: "Ratanada, Jodhpur, Rajasthan 342011",
        },
        {
          id: "neha-paota",
          label: "Third party",
          recipient: "Neha Choudhary",
          phone: "",
          addressLine: "Paota Main Road",
          landmark: "Near Paota Circle",
          area: "Paota · 342006",
          address: "Neha · Paota",
          detail: "Paota, Jodhpur, Rajasthan 342006",
        },
      ],
      business: [
        {
          id: "work",
          label: "Work",
          recipient: "Shree Balaji Retail",
          phone: "+91 92518 93684",
          addressLine: "Pal Road",
          landmark: "Near the receiving entrance",
          area: "Pal Road · 342003",
          address: "Shree Balaji Retail",
          detail: "Pal Road, Jodhpur, Rajasthan 342003",
        },
        {
          id: "warehouse",
          label: "Warehouse",
          recipient: "Shree Balaji Retail",
          phone: "+91 92518 93684",
          addressLine: "Basni Industrial Area",
          landmark: "Warehouse receiving gate",
          area: "Basni · 342005",
          address: "Basni receiving point",
          detail: "Basni Industrial Area, Jodhpur, Rajasthan 342005",
        },
        {
          id: "home",
          label: "Home",
          recipient: "Dharmendra Choudhary",
          phone: "+91 92518 93684",
          addressLine: "Residency Road, Sardarpura",
          landmark: "Near Sardarpura Circle",
          area: "Sardarpura · 342003",
          address: "Home · Sardarpura",
          detail: "Sardarpura, Jodhpur, Rajasthan 342003",
        },
      ],
    },
    locations: {
      personal: {
        label: "Sardarpura · 342003",
        address: "Home · Sardarpura",
        detail: "Jodhpur, Rajasthan 342003",
      },
      business: {
        label: "Pal Road · 342003",
        address: "Shree Balaji Retail",
        detail: "Pal Road, Jodhpur, Rajasthan 342003",
      },
    },
    deliveryChoices: {
      personal: {
        title: "Today · 7:00–7:30 pm",
        detail: "All items in one delivery",
        fee: null,
      },
      business: {
        title: "Tomorrow · 10:00 am–2:00 pm",
        detail: "Supplier commitments shown in the purchase order",
        fee: 0,
      },
    },
    carts: {
      personal: reviewSeed === "medicine-cart"
        ? new Map([
            ["medicine:paracetamol-500", {
              kind: "medicine",
              quantity: 1,
              packIndex: 0,
            }],
            ["medicine:ors-hydration", {
              kind: "medicine",
              quantity: 2,
              packIndex: 0,
            }],
          ])
        : reviewSeed === "mixed-cart"
          ? new Map([
              ["milk", { quantity: 1, packIndex: 0 }],
              ["medicine:paracetamol-500", {
                kind: "medicine",
                quantity: 1,
                packIndex: 0,
              }],
            ])
        : reviewSeed === "retail-cart" || reviewSeed === "combined-cart"
        ? new Map([
            ["household-basket:monthly-home", {
              kind: "household-basket",
              basketId: "monthly-home",
              members: 4,
              quantity: 1,
              packIndex: 0,
            }],
            ["milk", { quantity: 1, packIndex: 0 }],
          ])
        : reviewSeed === "1"
          ? new Map([
              ["tomato", { quantity: 1, packIndex: 0 }],
              ["atta", { quantity: 1, packIndex: 0 }],
            ])
          : new Map(),
      business: reviewSeed === "combined-cart" || reviewSeed === "mixed-cart"
        ? new Map([
            ["thermal-rolls", { quantity: 2, packIndex: 0 }],
          ])
        : reviewSeed === "1"
        ? new Map([
            ["atta", { quantity: 2, packIndex: 0 }],
          ])
        : new Map(),
    },
    lastOrders: {
      personal: new Map([
        ["tomato", { quantity: 1, packIndex: 0 }],
        ["atta", { quantity: 1, packIndex: 0 }],
        ["rice", { quantity: 1, packIndex: 0 }],
      ]),
      business: new Map([
        ["atta", { quantity: 2, packIndex: 0 }],
        ["oil", { quantity: 2, packIndex: 0 }],
      ]),
    },
  };

  const filterProfiles = {
    personal: {
      kicker: "Shop",
      title: "Choose what matters",
      resultLabel: "shop products",
      groups: [
        {
          id: "timing",
          label: "Delivery",
          glyph: "↗",
          choices: [
            { value: "anytime", label: "Anytime", note: "Every available window" },
            { value: "fast", label: "Fast delivery", note: "Minutes and same-day" },
            { value: "today", label: "Today", note: "Confirmed today" },
          ],
        },
        {
          id: "price",
          label: "Price",
          glyph: "₹",
          choices: [
            { value: "", label: "Best match", note: "Price, quality and delivery" },
            { value: "lowest-delivered", label: "Lowest delivered", note: "Final price first" },
          ],
        },
        {
          id: "term",
          label: "Seller & terms",
          glyph: "✓",
          choices: [
            { value: "", label: "All sellers", note: "Every verified option" },
            { value: "nearby", label: "Nearby sellers", note: "Local fulfilment" },
            { value: "returnable", label: "Easy returns", note: "Return or replacement" },
          ],
        },
      ],
    },
    business: {
      kicker: "Wholesale",
      title: "Set buying priorities",
      resultLabel: "wholesale products",
      groups: [
        {
          id: "timing",
          label: "Supply",
          glyph: "↗",
          choices: [
            { value: "anytime", label: "Any schedule", note: "Every confirmed window" },
            { value: "fast", label: "Fastest delivery", note: "Earliest supply first" },
            { value: "two-days", label: "Within 2 days", note: "Short fulfilment window" },
          ],
        },
        {
          id: "price",
          label: "Wholesale price",
          glyph: "₹",
          choices: [
            { value: "", label: "Best match", note: "MOQ, price and supply" },
            { value: "lowest-wholesale", label: "Lowest wholesale", note: "Unit price first" },
          ],
        },
        {
          id: "term",
          label: "Delivery terms",
          glyph: "✓",
          choices: [
            { value: "", label: "All terms", note: "Every verified supplier" },
            { value: "freight-included", label: "Freight included", note: "Delivered cost shown" },
            { value: "flexible-moq", label: "Flexible MOQ", note: "Lower minimum quantity" },
            { value: "manufacturer", label: "Manufacturer", note: "Direct supply offers" },
          ],
        },
      ],
    },
    medicine: {
      kicker: "Medicine",
      title: "Find the right supply",
      resultLabel: "health products",
      groups: [
        {
          id: "timing",
          label: "Delivery",
          glyph: "↗",
          choices: [
            { value: "anytime", label: "Anytime", note: "Every available window" },
            { value: "fast", label: "Fast delivery", note: "Nearby supply first" },
            { value: "today", label: "Today", note: "Confirmed today" },
          ],
        },
        {
          id: "price",
          label: "Price",
          glyph: "₹",
          choices: [
            { value: "", label: "Best match", note: "Medicine, price and delivery" },
            { value: "lowest-delivered", label: "Lowest delivered", note: "Final price first" },
          ],
        },
        {
          id: "term",
          label: "Supply",
          glyph: "Rx",
          choices: [
            { value: "", label: "All products", note: "Medicines and health" },
            { value: "otc", label: "Without Rx", note: "No prescription required" },
            { value: "nearby-pharmacy", label: "Nearby pharmacy", note: "Licensed local fulfilment" },
            { value: "manufacturer", label: "Manufacturer", note: "Direct health products" },
          ],
        },
      ],
    },
  };

  const activeFilterCount = (surface) => {
    const filters = state.filters[surface];
    if (!filters) return 0;
    return Number(filters.timing !== "anytime")
      + Number(Boolean(filters.price))
      + Number(Boolean(filters.term));
  };

  const hasActiveFilters = (surface) => activeFilterCount(surface) > 0;

  const filterChoice = (surface, groupId, value) =>
    filterProfiles[surface]?.groups
      .find((group) => group.id === groupId)?.choices
      .find((choice) => choice.value === value);

  const filterSummary = (surface, { includeDefaults = false } = {}) => {
    const filters = state.filters[surface];
    if (!filters) return "";
    return filterProfiles[surface].groups
      .map((group) => {
        const value = filters[group.id];
        if (!includeDefaults && (value === "" || value === "anytime")) return "";
        return filterChoice(surface, group.id, value)?.label || "";
      })
      .filter(Boolean)
      .join(" · ");
  };

  const addressStorageKey = "moolsocial-buy-addresses-v1";

  const normalizeAddressTypeLabel = (label) => {
    if (label === "Recipient" || label === "Someone else") return "Third party";
    if (label === "Other") return "Other place";
    if (label === "Warehouse") return "Work";
    return ["Home", "Work", "Third party", "Other place"].includes(label)
      ? label
      : "Other place";
  };

  const validAddress = (address) =>
    address &&
    typeof address.id === "string" &&
    typeof address.label === "string" &&
    typeof address.recipient === "string" &&
    typeof address.area === "string" &&
    typeof address.address === "string" &&
    typeof address.detail === "string";

  const persistAddresses = () => {
    try {
      window.localStorage.setItem(
        addressStorageKey,
        JSON.stringify({
          selectedAddressIds: state.selectedAddressIds,
          addressBook: state.addressBook,
        }),
      );
    } catch (_error) {
      // The review remains fully usable when private browsing blocks storage.
    }
  };

  const restoreAddresses = () => {
    try {
      const saved = JSON.parse(window.localStorage.getItem(addressStorageKey) || "null");
      if (!saved || typeof saved !== "object") return;
      ["personal", "business"].forEach((context) => {
        const addresses = saved.addressBook?.[context];
        if (Array.isArray(addresses) && addresses.length && addresses.every(validAddress)) {
          const singleUseLabels = new Set();
          state.addressBook[context] = [...addresses].reverse().filter((address) => {
            if (!["Home", "Work"].includes(address.label)) return true;
            if (singleUseLabels.has(address.label)) return false;
            singleUseLabels.add(address.label);
            return true;
          }).reverse().map((address) => ({
            ...address,
            label: normalizeAddressTypeLabel(address.label),
            phone: typeof address.phone === "string" ? address.phone : "",
            addressLine: typeof address.addressLine === "string"
              ? address.addressLine
              : address.detail.replace(/,\s*\d{6}\s*$/, ""),
            landmark: typeof address.landmark === "string" ? address.landmark : "",
            mapsLink: typeof address.mapsLink === "string" ? address.mapsLink : "",
          }));
        }
        const selected = saved.selectedAddressIds?.[context];
        if (state.addressBook[context].some((address) => address.id === selected)) {
          state.selectedAddressIds[context] = selected;
        }
      });
    } catch (_error) {
      // Ignore invalid saved review data and retain the safe defaults.
    }
  };

  const selectedAddress = (context = state.addressContext) => {
    const addresses = state.addressBook[context];
    return addresses.find((address) => address.id === state.selectedAddressIds[context])
      || addresses[0];
  };

  const syncLocationFromAddress = (context) => {
    const address = selectedAddress(context);
    state.locations[context] = {
      label: address.area,
      address: address.address,
      detail: address.detail,
    };
  };

  const selectAddress = (context, id) => {
    if (!state.addressBook[context].some((address) => address.id === id)) return false;
    state.selectedAddressIds[context] = id;
    state.addressConfirmationKey = null;
    syncLocationFromAddress(context);
    persistAddresses();
    return true;
  };

  restoreAddresses();
  syncLocationFromAddress("personal");
  syncLocationFromAddress("business");
  persistAddresses();

  const medicineCategorySet = [
    { id: "rx", label: "Prescription", glyph: "Rx" },
    { id: "pain-fever", label: "Pain & fever", glyph: "＋" },
    { id: "diabetes", label: "Diabetes", glyph: "◒" },
    { id: "heart-bp", label: "Heart & BP", glyph: "♥" },
    { id: "digestive", label: "Digestive", glyph: "◇" },
    { id: "respiratory", label: "Respiratory", glyph: "≈" },
    { id: "allergy", label: "Allergy", glyph: "✦" },
    { id: "vitamins", label: "Vitamins", glyph: "V" },
    { id: "first-aid", label: "First aid", glyph: "✚" },
    { id: "devices", label: "Devices", glyph: "▣" },
    { id: "women-care", label: "Women care", glyph: "○" },
    { id: "baby-care", label: "Baby care", glyph: "◎" },
    { id: "skin-care", label: "Skin care", glyph: "◐" },
  ];

  const medicineProducts = [
    {
      id: "paracetamol-500",
      title: "Paracetamol 500 mg tablets",
      brand: "Relief 500",
      category: "pain-fever",
      composition: "Paracetamol 500 mg",
      pack: "Strip of 15 tablets",
      unit: "₹1.87/tablet",
      mrp: 34,
      price: 28,
      seller: "Sardarpura Health Pharmacy",
      note: "Expiry and batch shown before dispatch",
      prescriptionRequired: false,
      visual: "box",
      label: "500",
      accent: "#e06b39",
      soft: "#fff0e8",
    },
    {
      id: "pain-relief-gel",
      title: "Pain relief gel",
      brand: "FlexiRelief",
      category: "pain-fever",
      composition: "Diclofenac gel 1% w/w",
      pack: "30 g tube",
      unit: "₹3.30/g",
      mrp: 118,
      price: 99,
      seller: "Jodhpur Care Pharmacy",
      note: "Sealed tube",
      prescriptionRequired: false,
      visual: "tube",
      label: "GEL",
      accent: "#a74b4b",
      soft: "#f9e7e7",
    },
    {
      id: "metformin-500",
      title: "Metformin SR 500 mg",
      brand: "Glyco SR",
      category: "diabetes",
      composition: "Metformin 500 mg sustained release",
      pack: "Strip of 10 tablets",
      unit: "₹2.90/tablet",
      mrp: 36,
      price: 29,
      seller: "Sardarpura Health Pharmacy",
      note: "Pharmacist review required",
      prescriptionRequired: true,
      visual: "box",
      label: "SR 500",
      accent: "#3b7f76",
      soft: "#e1f3ef",
    },
    {
      id: "glucose-strips",
      title: "Blood glucose test strips",
      brand: "GlucoCheck",
      category: "diabetes",
      composition: "Compatible capillary glucose strips",
      pack: "Vial of 50 strips",
      unit: "₹11.98/strip",
      mrp: 690,
      price: 599,
      seller: "Marwar Wellness Pharmacy",
      note: "Check meter compatibility",
      prescriptionRequired: false,
      visual: "bottle",
      label: "50",
      accent: "#347f9c",
      soft: "#e3f2f7",
    },
    {
      id: "telmisartan-40",
      title: "Telmisartan 40 mg tablets",
      brand: "TelmiCare 40",
      category: "heart-bp",
      composition: "Telmisartan 40 mg",
      pack: "Strip of 10 tablets",
      unit: "₹8.60/tablet",
      mrp: 112,
      price: 86,
      seller: "Sardarpura Health Pharmacy",
      note: "Pharmacist review required",
      prescriptionRequired: true,
      visual: "box",
      label: "40",
      accent: "#bc475f",
      soft: "#f9e6ea",
    },
    {
      id: "atorvastatin-10",
      title: "Atorvastatin 10 mg tablets",
      brand: "LipiCare 10",
      category: "heart-bp",
      composition: "Atorvastatin 10 mg",
      pack: "Strip of 10 tablets",
      unit: "₹5.40/tablet",
      mrp: 74,
      price: 54,
      seller: "Marwar Wellness Pharmacy",
      note: "Pharmacist review required",
      prescriptionRequired: true,
      visual: "box",
      label: "10",
      accent: "#7559a6",
      soft: "#eee8fa",
    },
    {
      id: "pantoprazole-40",
      title: "Pantoprazole 40 mg tablets",
      brand: "PantoCare 40",
      category: "digestive",
      composition: "Pantoprazole 40 mg",
      pack: "Strip of 15 tablets",
      unit: "₹4.60/tablet",
      mrp: 88,
      price: 69,
      seller: "Sardarpura Health Pharmacy",
      note: "Pharmacist review required",
      prescriptionRequired: true,
      visual: "box",
      label: "40",
      accent: "#9a7035",
      soft: "#f8efdd",
    },
    {
      id: "ors-hydration",
      title: "ORS hydration salts",
      brand: "HydraORS",
      category: "digestive",
      composition: "Oral rehydration salts",
      pack: "Pack of 5 sachets",
      unit: "₹4.80/sachet",
      mrp: 30,
      price: 24,
      seller: "Marwar Wellness Pharmacy",
      note: "Sealed single-use sachets",
      prescriptionRequired: false,
      visual: "sachet",
      label: "ORS",
      accent: "#dd8741",
      soft: "#fff0df",
    },
    {
      id: "salbutamol-inhaler",
      title: "Salbutamol inhaler",
      brand: "Breathe 100",
      category: "respiratory",
      composition: "Salbutamol 100 mcg per actuation",
      pack: "200 metered doses",
      unit: "₹0.77/dose",
      mrp: 176,
      price: 154,
      seller: "Jodhpur Care Pharmacy",
      note: "Pharmacist review required",
      prescriptionRequired: true,
      visual: "inhaler",
      label: "100",
      accent: "#2e77a7",
      soft: "#e2f0f9",
    },
    {
      id: "steam-inhaler",
      title: "Steam inhaler",
      brand: "BreatheEasy",
      category: "respiratory",
      composition: "Electric steam vaporiser",
      pack: "1 device",
      unit: "₹399/device",
      mrp: 499,
      price: 399,
      seller: "Jodhpur Care Pharmacy",
      note: "One-year manufacturer warranty",
      prescriptionRequired: false,
      visual: "device",
      label: "STEAM",
      accent: "#4b83a6",
      soft: "#e6f1f6",
    },
    {
      id: "cetirizine-10",
      title: "Cetirizine 10 mg tablets",
      brand: "AllerCare 10",
      category: "allergy",
      composition: "Cetirizine 10 mg",
      pack: "Strip of 10 tablets",
      unit: "₹2.40/tablet",
      mrp: 32,
      price: 24,
      seller: "Sardarpura Health Pharmacy",
      note: "Pharmacist review may be required",
      prescriptionRequired: true,
      visual: "box",
      label: "10",
      accent: "#4778ad",
      soft: "#e6eef8",
    },
    {
      id: "saline-nasal-spray",
      title: "Saline nasal spray",
      brand: "ClearNose",
      category: "allergy",
      composition: "Isotonic sodium chloride spray",
      pack: "20 ml bottle",
      unit: "₹6.45/ml",
      mrp: 149,
      price: 129,
      seller: "Marwar Wellness Pharmacy",
      note: "Sealed spray bottle",
      prescriptionRequired: false,
      visual: "spray",
      label: "SALINE",
      accent: "#3884a4",
      soft: "#e0f2f7",
    },
    {
      id: "vitamin-d3",
      title: "Vitamin D3 60,000 IU",
      brand: "D3 Weekly",
      category: "vitamins",
      composition: "Cholecalciferol 60,000 IU",
      pack: "Strip of 4 capsules",
      unit: "₹35/capsule",
      mrp: 168,
      price: 140,
      seller: "Marwar Wellness Pharmacy",
      note: "Sealed blister pack",
      prescriptionRequired: false,
      visual: "box",
      label: "D3",
      accent: "#e69a26",
      soft: "#fff3d8",
    },
    {
      id: "calcium-d3",
      title: "Calcium with Vitamin D3",
      brand: "CalciDaily",
      category: "vitamins",
      composition: "Calcium carbonate with Vitamin D3",
      pack: "Bottle of 30 tablets",
      unit: "₹5.30/tablet",
      mrp: 189,
      price: 159,
      seller: "Marwar Wellness Pharmacy",
      note: "Sealed bottle",
      prescriptionRequired: false,
      visual: "bottle",
      label: "Ca+D3",
      accent: "#6e81b6",
      soft: "#edf0fa",
    },
    {
      id: "adhesive-bandages",
      title: "Adhesive bandages",
      brand: "SafeStrip",
      category: "first-aid",
      composition: "Sterile adhesive wound strips",
      pack: "Box of 20 strips",
      unit: "₹2.25/strip",
      mrp: 55,
      price: 45,
      seller: "Sardarpura Health Pharmacy",
      note: "Individually sealed strips",
      prescriptionRequired: false,
      visual: "box",
      label: "20",
      accent: "#cf664d",
      soft: "#faeae5",
    },
    {
      id: "antiseptic-liquid",
      title: "Antiseptic liquid",
      brand: "SafeClean",
      category: "first-aid",
      composition: "Chloroxylenol antiseptic liquid",
      pack: "250 ml bottle",
      unit: "₹0.46/ml",
      mrp: 132,
      price: 115,
      seller: "Jodhpur Care Pharmacy",
      note: "Sealed bottle",
      prescriptionRequired: false,
      visual: "bottle",
      label: "250",
      accent: "#8b5b38",
      soft: "#f4ebe3",
    },
    {
      id: "digital-thermometer",
      title: "Digital thermometer",
      brand: "TempSure",
      category: "devices",
      composition: "Digital oral and underarm thermometer",
      pack: "1 device",
      unit: "₹149/device",
      mrp: 199,
      price: 149,
      seller: "Sardarpura Health Pharmacy",
      note: "One-year manufacturer warranty",
      prescriptionRequired: false,
      visual: "device",
      label: "°C",
      accent: "#426b9a",
      soft: "#e7eff8",
    },
    {
      id: "bp-monitor",
      title: "Automatic BP monitor",
      brand: "PressureCare",
      category: "devices",
      composition: "Upper-arm digital blood pressure monitor",
      pack: "Monitor with adult cuff",
      unit: "₹1,349/device",
      mrp: 1699,
      price: 1349,
      seller: "Jodhpur Care Pharmacy",
      note: "Two-year manufacturer warranty",
      prescriptionRequired: false,
      visual: "device",
      label: "BP",
      accent: "#3a7198",
      soft: "#e5f0f6",
    },
    {
      id: "iron-folic-acid",
      title: "Iron and folic acid tablets",
      brand: "IronDaily",
      category: "women-care",
      composition: "Ferrous ascorbate with folic acid",
      pack: "Strip of 15 tablets",
      unit: "₹6.60/tablet",
      mrp: 118,
      price: 99,
      seller: "Marwar Wellness Pharmacy",
      note: "Pharmacist guidance available",
      prescriptionRequired: false,
      visual: "box",
      label: "Fe",
      accent: "#a84f73",
      soft: "#f7e7ee",
    },
    {
      id: "pregnancy-test",
      title: "Pregnancy test kit",
      brand: "EarlyCheck",
      category: "women-care",
      composition: "Single-use urine test",
      pack: "1 test kit",
      unit: "₹62/kit",
      mrp: 75,
      price: 62,
      seller: "Sardarpura Health Pharmacy",
      note: "Private sealed packaging",
      prescriptionRequired: false,
      visual: "sachet",
      label: "TEST",
      accent: "#a64f87",
      soft: "#f6e7f1",
    },
    {
      id: "baby-rash-cream",
      title: "Baby rash protection cream",
      brand: "BabySoft",
      category: "baby-care",
      composition: "Zinc oxide barrier cream",
      pack: "50 g tube",
      unit: "₹3.38/g",
      mrp: 199,
      price: 169,
      seller: "Marwar Wellness Pharmacy",
      note: "Dermatologically tested",
      prescriptionRequired: false,
      visual: "tube",
      label: "BABY",
      accent: "#668bb4",
      soft: "#ebf3fb",
    },
    {
      id: "infant-saline-drops",
      title: "Infant saline nasal drops",
      brand: "LittleBreath",
      category: "baby-care",
      composition: "Sterile normal saline drops",
      pack: "10 ml bottle",
      unit: "₹7.90/ml",
      mrp: 92,
      price: 79,
      seller: "Jodhpur Care Pharmacy",
      note: "Sealed dropper bottle",
      prescriptionRequired: false,
      visual: "spray",
      label: "SALINE",
      accent: "#4f8aae",
      soft: "#e6f3fa",
    },
    {
      id: "clotrimazole-cream",
      title: "Clotrimazole cream 1%",
      brand: "FungiCare",
      category: "skin-care",
      composition: "Clotrimazole 1% w/w",
      pack: "20 g tube",
      unit: "₹3.95/g",
      mrp: 94,
      price: 79,
      seller: "Sardarpura Health Pharmacy",
      note: "Pharmacist review may be required",
      prescriptionRequired: true,
      visual: "tube",
      label: "1%",
      accent: "#4d8b71",
      soft: "#e5f4ed",
    },
    {
      id: "sunscreen-spf50",
      title: "Broad-spectrum sunscreen",
      brand: "SunGuard SPF 50",
      category: "skin-care",
      composition: "UVA and UVB protection",
      pack: "50 g tube",
      unit: "₹7.98/g",
      mrp: 449,
      price: 399,
      seller: "Marwar Wellness Pharmacy",
      note: "Dermatologically tested",
      prescriptionRequired: false,
      visual: "tube",
      label: "SPF 50",
      accent: "#dd8a2e",
      soft: "#fff0d9",
    },
  ];

  const savedPrescriptionRecords = [
    {
      name: "Heart & BP · Dr Meera Sharma",
      doctor: "Dr Meera Sharma",
      specialty: "Heart & BP",
      issued: "08 July 2026",
      productIds: ["telmisartan-40", "atorvastatin-10"],
    },
    {
      name: "Diabetes · Dr Arvind Joshi",
      doctor: "Dr Arvind Joshi",
      specialty: "Diabetes",
      issued: "19 June 2026",
      productIds: ["metformin-500"],
    },
  ];

  const prescriptionProductsForIds = (ids) =>
    [...new Set(ids || [])]
      .map((id) => medicineProducts.find((product) => product.id === id))
      .filter((product) => product?.prescriptionRequired);

  const relatedPrescriptionProductIds = (productId) => {
    const product = medicineProducts.find((item) => item.id === productId);
    if (!product?.prescriptionRequired) return [];
    return medicineProducts
      .filter((item) => item.prescriptionRequired && item.category === product.category)
      .map((item) => item.id);
  };

  const prescriptionCoverageProducts = () =>
    prescriptionProductsForIds(state.prescriptionMatchedProductIds);

  const setPrescriptionCoverage = (ids) => {
    const matchedProducts = prescriptionProductsForIds(ids);
    state.prescriptionMatchedProductIds = new Set(
      matchedProducts.map((product) => product.id),
    );
    return matchedProducts;
  };

  const setSavedPrescriptionCoverage = (name) => {
    const record = savedPrescriptionRecords.find((item) => item.name === name);
    return setPrescriptionCoverage(
      record?.productIds
        || relatedPrescriptionProductIds(state.prescriptionProduct),
    );
  };

  const setUploadedPrescriptionCoverage = () => {
    const selectedMatches = relatedPrescriptionProductIds(state.prescriptionProduct);
    return setPrescriptionCoverage(
      selectedMatches.length
        ? selectedMatches
        : savedPrescriptionRecords[0].productIds,
    );
  };

  const approvePrescriptionCoverage = () => {
    const covered = prescriptionCoverageProducts();
    if (!covered.length && state.prescriptionProduct) {
      setPrescriptionCoverage([state.prescriptionProduct]);
    }
    prescriptionCoverageProducts().forEach((product) => {
      state.rxApprovedProductIds.add(product.id);
    });
  };

  const savedPrescriptionOptionsHtml = () => {
    const records = state.prescriptionProduct
      ? savedPrescriptionRecords.filter((record) =>
          record.productIds.includes(state.prescriptionProduct))
      : savedPrescriptionRecords;
    if (!records.length) {
      return `
        <div class="prescription-no-match">
          <strong>No saved prescription contains this medicine</strong>
          <span>Add the prescription that lists this medicine.</span>
        </div>`;
    }
    return records.map((record) => `
      <button class="past-prescription-option" type="button"
        data-sheet-action="use-saved-prescription"
        data-prescription-name="${escapeHtml(record.name)}">
        <span aria-hidden="true">Rx</span>
        <span><strong>${escapeHtml(record.doctor)}</strong><small>${escapeHtml(record.specialty)} · issued ${escapeHtml(record.issued)}</small><em>${record.productIds.length} ${record.productIds.length === 1 ? "medicine" : "medicines"} listed</em></span>
        <b>Use</b>
      </button>`).join("");
  };

  const prescriptionQuoteProduct = {
    id: "prescription-quote",
    title: "Prescription order",
    category: "prescription",
    pack: "3 reviewed medicines",
    unit: "Pharmacist quote",
    price: 684,
    seller: "Sardarpura Health Pharmacy",
    note: "Medicine, strength and quantity pharmacist-verified",
    glyph: "Rx",
  };

  const views = [...document.querySelectorAll("[data-view]")];
  const productGrid = document.querySelector("[data-product-grid]");
  const productGridWide = document.querySelector("[data-product-grid-wide]");
  const relatedProducts = document.querySelector("[data-related-products]");
  const relatedProductGrid = document.querySelector("[data-related-product-grid]");
  const relatedKicker = document.querySelector("[data-related-kicker]");
  const relatedTitle = document.querySelector("[data-related-title]");
  const emptyResults = document.querySelector("[data-empty-results]");
  const search = document.querySelector("[data-search]");
  const contextSwipeSurface = document.querySelector("[data-buy-stage]");
  const contextTabRail = document.querySelector("[data-mode-switch]");
  const categoryItems = document.querySelector("[data-category-items]");
  const categoryRail = document.querySelector("[data-category-rail]");
  const catalogueResults = productGrid.closest(".catalogue-results");
  const catalogueScopeKicker = document.querySelector("[data-catalogue-scope-kicker]");
  const catalogueScopeTitle = document.querySelector("[data-catalogue-scope-title]");
  const catalogueScopeCount = document.querySelector("[data-catalogue-scope-count]");
  const householdBaskets = document.querySelector("[data-household-baskets]");
  const householdBasketCard = document.querySelector("[data-household-basket-card]");
  const subcategoryRow = document.querySelector("[data-subcategory-row]");
  const catalogueActiveFilterRow = document.querySelector("[data-active-filter-row]");
  const catalogueActiveFilter = document.querySelector("[data-active-filter]");
  const catalogueFilterCount = document.querySelector("[data-catalogue-filter-count]");
  const medicineSearch = document.querySelector("[data-medicine-search]");
  const medicineResults = document.querySelector("[data-medicine-results]");
  const medicineResultsWide = document.querySelector("[data-medicine-results-wide]");
  const medicineResultsTitle = document.querySelector("[data-medicine-results-title]");
  const medicineActiveFilterRow = document.querySelector("[data-medicine-active-filter-row]");
  const medicineActiveFilter = document.querySelector("[data-medicine-active-filter]");
  const medicineFilterCount = document.querySelector("[data-medicine-filter-count]");
  const medicineCategoryRail = document.querySelector("[data-medicine-category-rail]");
  const medicineCatalogueResults = medicineResults.closest(".medicine-catalogue-results");
  const medicineCategoryItems = document.querySelector("[data-medicine-category-items]");
  const medicineCategoryMore = document.querySelector("[data-medicine-category-more]");
  const medicineScopeCount = document.querySelector("[data-medicine-scope-count]");
  const medicineCategoryTotal = document.querySelector("[data-medicine-category-total]");
  const prescriptionCard = document.querySelector("[data-prescription-card]");
  const savedRxNote = document.querySelector("[data-saved-rx-note]");
  const pharmacistNote = document.querySelector("[data-pharmacist-note]");
  const refillNote = document.querySelector("[data-refill-note]");
  const ordersList = document.querySelector("[data-orders-list]");
  const ordersEmpty = document.querySelector("[data-orders-empty]");
  const liveOrderStatus = document.querySelector("[data-live-order-status]");
  const clearSearch = document.querySelector("[data-action='clear-search']");
  const sheetLayer = document.querySelector("[data-sheet-layer]");
  const sheet = document.querySelector("[data-sheet]");
  const sheetDragHandles = [...document.querySelectorAll("[data-sheet-drag-handle]")];
  const sheetTitle = document.querySelector("[data-sheet-title]");
  const sheetKicker = document.querySelector("[data-sheet-kicker]");
  const sheetContent = document.querySelector("[data-sheet-content]");
  const noticeLayer = document.querySelector("[data-notice-layer]");
  const toast = document.querySelector("[data-toast]");
  let toastTimer;
  let cartNoticeTimer;
  let contextMotionTimer;
  let contextSwipeStart = null;
  let suppressContextClick = false;
  let sheetSwipeStart = null;
  let sheetCloseTimer;
  let scrollAudioContext = null;
  let lastManualScrollIntent = 0;
  let lastScrollDetentAt = 0;
  const scrollDetents = new WeakMap();

  const alignCategoryRail = (rail, results) => {
    if (!rail || !results || results.hidden) return;
    const contentHeight = Math.ceil(
      Math.max(results.scrollHeight, results.getBoundingClientRect().height),
    );
    rail.style.height = `${Math.max(1, contentHeight)}px`;
  };

  const query = () => new URLSearchParams(window.location.search);
  const discovery = () => state.discovery[state.context];
  const productCategory = (product) =>
    state.context === "business" ? product.businessCategory : product.category;
  const productSubcategory = (product) =>
    state.context === "business" ? product.businessSubcategory : product.subcategory;
  const availableCategories = () => categorySets[state.context];
  const availableSubcategories = (category = discovery().category) =>
    subcategorySets[state.context][category] || [];

  const renderFilterStatus = (surface) => {
    const count = activeFilterCount(surface);
    const summary = filterSummary(surface);
    if (surface === "medicine") {
      medicineActiveFilterRow.hidden = count === 0;
      medicineActiveFilter.textContent = summary;
      medicineFilterCount.hidden = count === 0;
      medicineFilterCount.textContent = String(count);
      return;
    }
    if (surface !== state.context) return;
    catalogueActiveFilterRow.hidden = count === 0;
    catalogueActiveFilter.textContent = summary;
    catalogueFilterCount.hidden = count === 0;
    catalogueFilterCount.textContent = String(count);
  };

  app.dataset.medicineProducts = String(medicineProducts.length);
  app.dataset.medicineCategories = String(medicineCategorySet.length);
  app.dataset.medicinePrescriptionProducts = String(
    medicineProducts.filter((product) => product.prescriptionRequired).length,
  );
  const isCategoryAvailable = (category) =>
    availableCategories().some((item) => item.id === category && !item.view);
  const isSubcategoryAvailable = (subcategory, category = discovery().category) =>
    subcategory === "all" || availableSubcategories(category).includes(subcategory);
  const hapticTick = () => {
    if (typeof navigator.vibrate === "function") navigator.vibrate(8);
  };

  const unlockScrollAudio = () => {
    lastManualScrollIntent = performance.now();
    if (window.matchMedia("(prefers-reduced-motion: reduce)").matches) return;
    const AudioContext = window.AudioContext || window.webkitAudioContext;
    if (!AudioContext) return;
    scrollAudioContext ||= new AudioContext();
    if (scrollAudioContext.state === "suspended") {
      scrollAudioContext.resume().catch(() => {});
    }
  };

  const playScrollDetent = () => {
    if (
      !scrollAudioContext
      || scrollAudioContext.state !== "running"
      || window.matchMedia("(prefers-reduced-motion: reduce)").matches
    ) return;
    const now = scrollAudioContext.currentTime;
    const oscillator = scrollAudioContext.createOscillator();
    const gain = scrollAudioContext.createGain();
    oscillator.type = "square";
    oscillator.frequency.setValueAtTime(760, now);
    oscillator.frequency.exponentialRampToValueAtTime(520, now + 0.018);
    gain.gain.setValueAtTime(0.006, now);
    gain.gain.exponentialRampToValueAtTime(0.0001, now + 0.02);
    oscillator.connect(gain);
    gain.connect(scrollAudioContext.destination);
    oscillator.start(now);
    oscillator.stop(now + 0.021);
  };

  const handleScrollDetent = (event) => {
    const now = performance.now();
    if (now - lastManualScrollIntent > 900 || now - lastScrollDetentAt < 72) return;
    const scroller = event.target === document
      ? document.scrollingElement
      : event.target;
    if (!(scroller instanceof Element)) return;
    const position = {
      x: Math.round(scroller.scrollLeft || 0),
      y: Math.round(scroller.scrollTop || 0),
    };
    const previous = scrollDetents.get(scroller);
    if (!previous) {
      scrollDetents.set(scroller, position);
      return;
    }
    if (Math.max(Math.abs(position.x - previous.x), Math.abs(position.y - previous.y)) < 34) return;
    scrollDetents.set(scroller, position);
    lastScrollDetentAt = now;
    playScrollDetent();
    if (typeof navigator.vibrate === "function") navigator.vibrate(3);
  };

  const packMeasure = (label) => {
    const value = String(label || "").trim().toLowerCase();
    const prefixed = value.match(/^(\d+(?:\.\d+)?)\s*[×x]\s*(.+)$/);
    if (prefixed) {
      const inner = packMeasure(prefixed[2]);
      return inner
        ? { ...inner, value: inner.value * Number(prefixed[1]) }
        : { kind: "count", value: Number(prefixed[1]) };
    }
    const multipliedMeasure = value.match(
      /(\d+(?:\.\d+)?)\s*[×x]\s*(\d+(?:\.\d+)?)\s*(kg|g|l|ml)\b/,
    );
    if (multipliedMeasure) {
      const count = Number(multipliedMeasure[1]);
      const amount = Number(multipliedMeasure[2]);
      const unit = multipliedMeasure[3];
      const normalized = unit === "kg" || unit === "l" ? amount * 1000 : amount;
      return {
        kind: unit === "kg" || unit === "g" ? "mass" : "volume",
        value: count * normalized,
      };
    }
    const measure = value.match(/(\d+(?:\.\d+)?)\s*(kg|g|l|ml)\b/);
    if (measure) {
      const amount = Number(measure[1]);
      const unit = measure[2];
      return {
        kind: unit === "kg" || unit === "g" ? "mass" : "volume",
        value: unit === "kg" || unit === "l" ? amount * 1000 : amount,
      };
    }
    const counted = value.match(
      /(?:case|carton|pack|box|pallet|bundle)\s+of\s+(\d+(?:\.\d+)?)/,
    );
    return counted ? { kind: "count", value: Number(counted[1]) } : null;
  };

  const packPrice = (offer, packIndex, context = state.context) => {
    const selectedPack = offer.packs[packIndex] || offer.packs[0];
    const explicitPrice = Number(selectedPack?.[2]);
    if (Number.isFinite(explicitPrice) && explicitPrice > 0) return explicitPrice;
    if (context === "personal") {
      const match = selectedPack?.[1]?.match(/₹([\d,]+(?:\.\d+)?)/);
      return match ? Number(match[1].replace(/,/g, "")) : offer.price;
    }
    const baseMeasure = packMeasure(offer.packs[0]?.[0] || offer.pack);
    const selectedMeasure = packMeasure(selectedPack?.[0]);
    const ratio =
      baseMeasure &&
      selectedMeasure &&
      baseMeasure.kind === selectedMeasure.kind &&
      baseMeasure.value > 0
        ? selectedMeasure.value / baseMeasure.value
        : 1;
    return Math.max(1, Math.round(offer.price * ratio));
  };

  const sellerPackPrice = (offer, seller, packIndex, context = state.context) => {
    const selectedPackPrice = packPrice(offer, packIndex, context);
    if (!seller || !offer.price) return selectedPackPrice;
    return Math.max(1, Math.round(selectedPackPrice * (seller[3] / offer.price)));
  };

  const packMinimum = (offer, packIndex, context = state.context) => {
    if (context !== "business") return 1;
    const note = offer.packs[packIndex]?.[1] || "";
    const match = note.match(/MOQ\s+(\d+)/i);
    return match ? Number(match[1]) : 1;
  };

  const formatMeasure = (measure) => {
    if (!measure) return "1 pack";
    if (measure.kind === "mass") {
      return measure.value >= 1000
        ? `${Number((measure.value / 1000).toFixed(2))} kg`
        : `${Number(measure.value.toFixed(0))} g`;
    }
    if (measure.kind === "volume") {
      return measure.value >= 1000
        ? `${Number((measure.value / 1000).toFixed(2))} L`
        : `${Number(measure.value.toFixed(0))} ml`;
    }
    return `${Number(measure.value.toFixed(0))} units`;
  };

  const packFacts = (
    product,
    packIndex = state.selectedPack,
    quantity = 1,
    context = state.context,
  ) => {
    const offer = product[context];
    const selectedPack = offer.packs[packIndex] || offer.packs[0];
    const measure = packMeasure(selectedPack[0]);
    const totalMeasure = measure
      ? { ...measure, value: measure.value * Math.max(1, quantity) }
      : null;
    return {
      name: selectedPack[0],
      netPerPack: formatMeasure(measure),
      minimum: packMinimum(offer, packIndex, context),
      ordered: `${quantity} ${context === "business"
        ? quantity === 1 ? "trade pack" : "trade packs"
        : quantity === 1 ? "pack" : "packs"} · ${formatMeasure(totalMeasure)}`,
    };
  };

  const supplierOrigin = (seller, sellerType = "") => {
    const name = String(seller || "").toLowerCase();
    const type = String(sellerType || "").toLowerCase();
    if (
      /jodhpur|sardarpura|shree balaji|ghar bazaar|marwar|thar|family stationery|school bazaar|rajasthan mart/.test(
        name,
      )
    ) {
      return { city: "Jodhpur", state: "Rajasthan", pin: "342001" };
    }
    if (
      /surya oils|care products|herbal brands|india|national/.test(name) ||
      (type.includes("manufacturer") && !/rajasthan|aravali/.test(name))
    ) {
      return { city: "Delhi", state: "Delhi", pin: "110020" };
    }
    if (/rajasthan|aravali|kisan|jaipur/.test(name)) {
      return { city: "Jaipur", state: "Rajasthan", pin: "302001" };
    }
    return { city: "Jodhpur", state: "Rajasthan", pin: "342001" };
  };

  const addDays = (date, days) => {
    const next = new Date(date);
    next.setDate(next.getDate() + days);
    return next;
  };

  const dayLabel = (date, includeWeekday = true) =>
    new Intl.DateTimeFormat("en-IN", {
      ...(includeWeekday ? { weekday: "short" } : {}),
      day: "numeric",
      month: "short",
    }).format(date);

  const destinationFor = (context = state.context) => {
    const location = state.locations[context];
    const pin = location.detail.match(/\b\d{6}\b/)?.[0] || "342003";
    return {
      city: "Jodhpur",
      state: "Rajasthan",
      pin,
      label: location.address,
    };
  };

  const deliveryCommitment = (
    product,
    offer,
    packIndex = state.selectedPack,
    context = state.context,
  ) => {
    const now = new Date();
    const orderDay = new Date(now);
    orderDay.setHours(0, 0, 0, 0);
    const origin = supplierOrigin(offer.seller, offer.sellerType);
    const destination = destinationFor(context);
    const sameCity = origin.city === destination.city;
    const business = context === "business";
    const cutoffHour = business ? 16 : sameCity ? 18 : 16;
    const afterCutoff = now.getHours() >= cutoffHour;
    const acceptedDay = addDays(orderDay, afterCutoff ? 1 : 0);
    const dispatchLead = business || !sameCity ? 1 : 0;
    const transitLead = sameCity ? 0 : origin.city === "Jaipur" ? 1 : 2;
    const dispatchDate = addDays(acceptedDay, dispatchLead);
    const deliveryStart = addDays(dispatchDate, transitLead);
    const deliveryEnd = addDays(deliveryStart, business && !sameCity ? 1 : 0);
    const sameDeliveryDay = deliveryStart.getTime() === deliveryEnd.getTime();
    const cutoffMoment = new Date(acceptedDay);
    cutoffMoment.setHours(cutoffHour, 0, 0, 0);
    const cutoffLabel = new Intl.DateTimeFormat("en-IN", {
      hour: "numeric",
      minute: "2-digit",
      hour12: true,
    }).format(cutoffMoment);
    const deliveryTime = !business && sameCity
      ? afterCutoff
        ? "by 10:00 am"
        : offer.delivery.match(/\d+\s+minutes/i)?.[0]
          ? `within ${offer.delivery.match(/\d+\s+minutes/i)[0]}`
          : `by ${offer.delivery.match(/by\s+(.+)$/i)?.[1] || "8:00 pm"}`
      : "";
    const delivery = sameDeliveryDay
      ? `${dayLabel(deliveryStart)}${deliveryTime ? ` · ${deliveryTime}` : ""}`
      : `${dayLabel(deliveryStart)} – ${dayLabel(deliveryEnd)}`;
    const orderBy = afterCutoff
      ? `${dayLabel(acceptedDay)} · ${cutoffLabel}`
      : `Today · ${cutoffLabel}`;
    const facts = packFacts(product, packIndex, 1, context);
    return {
      origin,
      destination,
      route: `${origin.city} → ${destination.city} ${destination.pin}`,
      orderBy,
      dispatch: dayLabel(dispatchDate),
      delivery,
      deliveryStart: deliveryStart.getTime(),
      deliveryEnd: deliveryEnd.getTime(),
      card: `${origin.city} → ${destination.city} · ${sameDeliveryDay
        ? dayLabel(deliveryStart, false)
        : `${dayLabel(deliveryStart, false)}–${dayLabel(deliveryEnd, false)}`}`,
      confirmed: `Confirmed ${dayLabel(now, false)}`,
      note: `${offer.seller} confirmed ${facts.name}, available quantity and delivery to ${destination.pin}.`,
    };
  };

  const scaleMoneyLabel = (label, factor) => {
    const match = String(label || "").match(/₹([\d,]+(?:\.\d+)?)/);
    if (!match || !Number.isFinite(factor)) return label;
    const amount = Number(match[1].replace(/,/g, ""));
    return String(label).replace(match[0], money(Math.max(1, Math.round(amount * factor))));
  };

  const scaleUnitLabel = (label, factor) => {
    const match = String(label || "").match(/₹([\d,]+(?:\.\d+)?)/);
    if (!match || !Number.isFinite(factor)) return label;
    const amount = Number(match[1].replace(/,/g, ""));
    return String(label).replace(match[0], unitMoney(Math.max(0.01, amount * factor)));
  };

  const productDecisionErrors = [];
  products.forEach((product) => {
    ["personal", "business"].forEach((context) => {
      const offer = product[context];
      if (!offer || offer.packs.length < 2 || offer.sellers.length < 2) {
        productDecisionErrors.push(`${product.id}:${context}:missing-choice`);
        return;
      }
      offer.packs.forEach((pack, packIndex) => {
        const selectedPackPrice = packPrice(offer, packIndex, context);
        if (!pack[0] || !pack[1] || !Number.isFinite(selectedPackPrice) || selectedPackPrice <= 0) {
          productDecisionErrors.push(`${product.id}:${context}:pack-${packIndex}`);
        }
        offer.sellers.forEach((seller, sellerIndex) => {
          const selectedSellerPrice = sellerPackPrice(offer, seller, packIndex, context);
          if (
            !seller[1] ||
            !seller[2] ||
            !Number.isFinite(selectedSellerPrice) ||
            selectedSellerPrice <= 0
          ) {
            productDecisionErrors.push(
              `${product.id}:${context}:pack-${packIndex}:seller-${sellerIndex}`,
            );
          }
        });
      });
    });
  });
  if (productDecisionErrors.length) {
    throw new Error(`Buy product-decision integrity failed: ${productDecisionErrors.join(", ")}`);
  }
  app.dataset.productDecisionProducts = String(products.length);
  app.dataset.productDecisionOffers = String(products.length * 2);
  app.dataset.productDecisionPackChoices = String(
    products.reduce(
      (total, product) => total + product.personal.packs.length + product.business.packs.length,
      0,
    ),
  );
  app.dataset.productDecisionSellerChoices = String(
    products.reduce(
      (total, product) => total + product.personal.sellers.length + product.business.sellers.length,
      0,
    ),
  );
  app.dataset.productPurchaseFacts = String(products.length * 2);
  app.dataset.supplierDeliveryCommitments = String(products.length * 2);

  const currentOffer = (product = state.currentProduct, packIndex = state.selectedPack) => {
    const offer = product[state.context];
    const selectedIndex = state.sellerChoices[state.context].get(product.id);
    const seller = Number.isInteger(selectedIndex) ? offer.sellers[selectedIndex] : null;
    const sellerNote = seller ? seller[2].split(" · ") : [];
    const selectedPack = offer.packs[packIndex] || offer.packs[0];
    const selectedPrice = sellerPackPrice(offer, seller, packIndex);
    let selectedUnit = offer.unit;
    if (state.context === "personal") {
      const weightMatch = selectedPack[0].match(/(\d+(?:\.\d+)?)\s*(kg|g|l)\b/i);
      const countMatch = selectedPack[0].match(/pack of\s+(\d+)/i);
      if (weightMatch) {
        const amount = Number(weightMatch[1]);
        const unit = weightMatch[2].toLowerCase();
        const normalizedAmount = unit === "g" ? amount / 1000 : amount;
        selectedUnit = `${unitMoney(selectedPrice / normalizedAmount)}/${unit === "l" ? "L" : "kg"}`;
      } else if (countMatch) {
        selectedUnit = `${unitMoney(selectedPrice / Number(countMatch[1]))} each`;
      }
    } else if (seller && offer.price) {
      selectedUnit = scaleUnitLabel(offer.unit, seller[3] / offer.price);
    }
    const resolvedOffer = {
      ...offer,
      pack: selectedPack[0],
      unit: selectedUnit,
      seller: seller ? seller[1] : offer.seller,
      sellerType: seller ? sellerNote[0] : offer.sellerType,
      delivery: seller ? (sellerNote.slice(1).join(" · ") || offer.delivery) : offer.delivery,
      price: selectedPrice,
      badge: seller ? seller[4] : offer.badge,
      packIndex,
      sellerIndex: Number.isInteger(selectedIndex) ? selectedIndex : null,
      variant: productVariant(product),
    };
    resolvedOffer.packFacts = packFacts(product, packIndex);
    resolvedOffer.commitment = deliveryCommitment(product, resolvedOffer, packIndex);
    return resolvedOffer;
  };

  const householdBasketOffers = [
    {
      id: "monthly-home",
      title: "Monthly home basket",
      seller: "Ghar Bazaar Sardarpura",
      sellerType: "Verified retailer",
      duration: "30 days",
      baseMembers: 4,
      discountRate: 0.08,
      items: [
        ["atta", 2],
        ["rice", 2],
        ["toor-dal", 4],
        ["oil", 1],
        ["sugar", 2],
        ["tea", 2],
        ["detergent", 1],
        ["dishwash", 2],
        ["toothpaste", 1],
        ["handwash", 2],
        ["garbage-bags", 1],
        ["floor-cleaner", 1],
      ],
    },
  ];
  app.dataset.householdBasketOffers = String(householdBasketOffers.length);

  const householdBasketKey = (id) => `household-basket:${id}`;
  const householdBasketOffer = (id) =>
    householdBasketOffers.find((offer) => offer.id === id);

  const householdBasketDetails = (
    id,
    members = state.householdBasketMembers[id],
  ) => {
    const basketOffer = householdBasketOffer(id);
    if (!basketOffer) return null;
    const safeMembers = Math.min(8, Math.max(2, Number(members) || basketOffer.baseMembers));
    const itemLines = basketOffer.items
      .map(([productId, baseQuantity]) => {
        const product = products.find((candidate) => candidate.id === productId);
        if (!product) return null;
        const quantity = Math.max(
          1,
          Math.round((baseQuantity * safeMembers) / basketOffer.baseMembers),
        );
        const price = packPrice(product.personal, 0, "personal");
        return {
          product,
          quantity,
          pack: product.personal.packs[0]?.[0] || product.personal.pack,
          lineTotal: price * quantity,
        };
      })
      .filter(Boolean);
    const regularTotal = itemLines.reduce((total, line) => total + line.lineTotal, 0);
    const price = Math.max(
      1,
      Math.round(regularTotal * (1 - basketOffer.discountRate)),
    );
    const firstProduct = itemLines[0]?.product || products[0];
    const commitment = deliveryCommitment(
      firstProduct,
      {
        ...firstProduct.personal,
        seller: basketOffer.seller,
        sellerType: basketOffer.sellerType,
      },
      0,
      "personal",
    );
    return {
      ...basketOffer,
      members: safeMembers,
      itemLines,
      itemCount: itemLines.length,
      packCount: itemLines.reduce((total, line) => total + line.quantity, 0),
      regularTotal,
      price,
      saving: regularTotal - price,
      commitment,
    };
  };

  const renderHouseholdBasketOffer = () => {
    const visible =
      state.context === "personal" &&
      discovery().category === "all" &&
      discovery().subcategory === "all" &&
      !discovery().search.trim() &&
      !hasActiveFilters("personal");
    householdBaskets.hidden = !visible;
    if (!visible) return;

    const details = householdBasketDetails("monthly-home");
    if (!details) {
      householdBaskets.hidden = true;
      return;
    }
    document.querySelector("[data-household-basket-saving]").textContent =
      `Save ${money(details.saving)}`;
    const inCart = state.carts.personal.has(householdBasketKey(details.id));
    householdBasketCard.innerHTML = `
      <div class="household-basket-summary">
        <span class="household-basket-art" aria-hidden="true">
          <span>${art.atta}</span><span>${art.rice}</span><span>${art.oil}</span><span>${art.soap}</span>
        </span>
        <span>
          <small>${details.seller}</small>
          <h3>${details.title}</h3>
          <p>${details.itemCount} products · ${details.packCount} packs · ${details.duration}</p>
        </span>
      </div>
      <div class="household-basket-controls">
        <span>
          <small>Household size</small>
          <strong>${details.members} ${details.members === 1 ? "member" : "members"}</strong>
        </span>
        <div class="household-member-stepper" role="group" aria-label="Household members">
          <button type="button" data-household-member-decrease="${details.id}"
            aria-label="Remove one household member" ${details.members <= 2 ? "disabled" : ""}>−</button>
          <b aria-live="polite">${details.members}</b>
          <button type="button" data-household-member-increase="${details.id}"
            aria-label="Add one household member" ${details.members >= 8 ? "disabled" : ""}>+</button>
        </div>
      </div>
      <div class="household-basket-price">
        <span>
          <small>Basket price</small>
          <strong>${money(details.price)}</strong>
          <del>${money(details.regularTotal)}</del>
        </span>
        <span>
          <small>Delivered</small>
          <strong>${details.commitment.delivery}</strong>
          <em>${details.commitment.confirmed}</em>
        </span>
      </div>
      <div class="household-basket-actions">
        <button type="button" data-action="toggle-household-basket"
          aria-expanded="${state.householdBasketExpanded}">
          ${state.householdBasketExpanded ? "Hide products" : `See ${details.itemCount} products`}
        </button>
        <button type="button" data-action="add-household-basket"
          data-household-basket-id="${details.id}">${inCart ? "Update cart" : "Add basket to cart"}</button>
      </div>
      <div class="household-basket-contents" data-household-basket-contents
        ${state.householdBasketExpanded ? "" : "hidden"}>
        ${details.itemLines
          .map(
            ({ product, quantity, pack }) => `
              <span>
                <b>${product.title}</b>
                <small>${quantity} × ${pack}</small>
              </span>`,
          )
          .join("")}
      </div>`;
  };

  const minimumQuantity = (product = state.currentProduct, packIndex = state.selectedPack) => {
    return packMinimum(product[state.context], packIndex);
  };

  const purchaseFactErrors = [];
  products.forEach((product) => {
    ["personal", "business"].forEach((context) => {
      const offer = product[context];
      if (!productVariant(product) || !offer.pack || !offer.unit || !offer.stock) {
        purchaseFactErrors.push(`${product.id}:${context}:purchase-facts`);
        return;
      }
      offer.packs.forEach((pack, packIndex) => {
        const facts = packFacts(product, packIndex, packMinimum(offer, packIndex, context), context);
        const resolved = {
          ...offer,
          pack: pack[0],
          seller: offer.seller,
          sellerType: offer.sellerType,
        };
        const commitment = deliveryCommitment(product, resolved, packIndex, context);
        if (
          !facts.name ||
          !facts.netPerPack ||
          !facts.ordered ||
          !commitment.route ||
          !commitment.orderBy ||
          !commitment.dispatch ||
          !commitment.delivery ||
          !commitment.confirmed
        ) {
          purchaseFactErrors.push(`${product.id}:${context}:pack-${packIndex}:commitment`);
        }
        offer.sellers.forEach((seller, sellerIndex) => {
          const note = seller[2].split(" · ");
          const sellerCommitment = deliveryCommitment(
            product,
            {
              ...offer,
              pack: pack[0],
              seller: seller[1],
              sellerType: note[0],
            },
            packIndex,
            context,
          );
          if (!sellerCommitment.origin.city || !sellerCommitment.delivery) {
            purchaseFactErrors.push(
              `${product.id}:${context}:pack-${packIndex}:seller-${sellerIndex}:commitment`,
            );
          }
        });
      });
    });
  });
  if (purchaseFactErrors.length) {
    throw new Error(`Buy purchase-fact integrity failed: ${purchaseFactErrors.join(", ")}`);
  }
  app.dataset.productPurchaseFactErrors = "0";
  app.dataset.supplierDeliveryCommitments = String(
    products.reduce(
      (total, product) =>
        total +
        product.personal.packs.length * product.personal.sellers.length +
        product.business.packs.length * product.business.sellers.length,
      0,
    ),
  );

  const renderLocation = () => {
    document.querySelector("[data-location-value]").textContent = state.locations[state.context].label;
  };

  const showToast = (message) => {
    clearTimeout(toastTimer);
    toast.textContent = message;
    toast.hidden = false;
    toastTimer = setTimeout(() => {
      toast.hidden = true;
    }, 2600);
  };

  const setUrl = (next, push = true) => {
    const params = query();
    Object.entries(next).forEach(([key, value]) => {
      if (value === "" || value === null || value === undefined) params.delete(key);
      else params.set(key, value);
    });
    const serialized = params.toString();
    const url = `${window.location.pathname}${serialized ? `?${serialized}` : ""}`;
    const method = push ? "pushState" : "replaceState";
    window.history[method]({}, "", url);
  };

  const visibleView = () => document.querySelector("[data-view].active")?.dataset.view || "catalogue";

  const setDock = (view) => {
    document.querySelectorAll("[data-nav]").forEach((button) => {
      const nav = button.dataset.nav;
      const shoppingView = ["catalogue", "product", "basket", "checkout"].includes(view);
      const active =
        (nav === "retail" && shoppingView && state.context === "personal") ||
        (nav === "wholesale" && shoppingView && state.context === "business") ||
        (nav === "medicine" && view === "medicine") ||
        (nav === "orders" && ["orders", "confirmed", "tracking"].includes(view));
      button.classList.toggle("active", active);
      if (active) button.setAttribute("aria-current", "page");
      else button.removeAttribute("aria-current");
      if (nav === "retail" && ["product", "basket", "checkout"].includes(view) && state.context === "personal") {
        button.setAttribute("aria-label", "Return to Shop");
      } else if (nav === "wholesale" && ["product", "basket", "checkout"].includes(view) && state.context === "business") {
        button.setAttribute("aria-label", "Return to Wholesale catalogue");
      } else if (nav === "medicine" && view === "medicine") {
        button.setAttribute("aria-label", "Medicine");
      } else if (nav === "orders" && view === "tracking") {
        button.setAttribute("aria-label", "Return to Orders");
      } else {
        button.removeAttribute("aria-label");
      }
    });
  };

  const showView = (name, { push = true, restoreCatalogueScroll = false } = {}) => {
    views.forEach((view) => view.classList.toggle("active", view.dataset.view === name));
    app.dataset.activeView = name;
    setDock(name);
    const nextUrl = { view: name === "catalogue" ? null : name };
    if (name === "basket") {
      nextUrl.cart = state.cartScope;
      nextUrl.cartReturn = state.cartReturnView;
    } else {
      nextUrl.cart = null;
      nextUrl.cartReturn = null;
    }
    if (name !== "product") nextUrl.product = null;
    if (name !== "medicine") nextUrl.med = null;
    else nextUrl.med = state.medicineCategory === "all" ? null : state.medicineCategory;
    if (name !== "tracking") nextUrl.received = null;
    if (name !== "tracking") nextUrl.order = null;
    if (name !== "orders") nextUrl.orders = null;
    if (name !== "confirmed") nextUrl.confirm = null;
    setUrl(nextUrl, push);
    const pill = document.querySelector("[data-action='basket'].basket-pill");
    pill.hidden = !["catalogue", "medicine"].includes(name) ||
      (cartStats("personal").count + cartStats("business").count === 0);
    if (name === "basket") renderBasket();
    if (name === "checkout") renderCheckout();
    if (name === "medicine") renderMedicine();
    if (name === "confirmed") renderConfirmation();
    if (name === "orders") renderOrders();
    if (name === "tracking") renderTracking();
    renderLiveOrderStatus(name);
    document.querySelector("[data-buy-stage]")?.scrollTo?.({ top: 0 });
    window.scrollTo({
      top: name === "catalogue" && restoreCatalogueScroll
        ? state.catalogueScroll[state.context]
        : 0,
      behavior: restoreCatalogueScroll ? "auto" : "smooth",
    });
  };

  const productVisual = (product) => `
    <div class="product-visual" style="--product-light:${product.colors[0]};--product-soft:${product.colors[1]}">
      ${art[product.visual]}
    </div>`;

  const renderCategories = () => {
    const selectedCategory = discovery().category;
    const regularCategories = availableCategories().filter((item) => item.id !== "all" && !item.view);
    const allRailCategories = availableCategories().filter((item) => item.id !== "all");
    const compactLimit = 5;
    const railExpanded = state.categoryRailExpanded[state.context];
    let visibleCategories = railExpanded
      ? allRailCategories
      : allRailCategories.slice(0, compactLimit);
    if (!railExpanded) {
      const selectedItem = allRailCategories.find(
        (item) => !item.view && item.id === selectedCategory,
      );
      const selectedIsVisible = visibleCategories.some((item) => item.id === selectedCategory);
      if (selectedItem && !selectedIsVisible) {
        visibleCategories = [...visibleCategories.slice(0, compactLimit - 1), selectedItem];
      }
    }

    categoryItems.innerHTML = visibleCategories
      .map((item) => {
        const active = !item.view && item.id === selectedCategory;
        const target = item.view
          ? `data-category-view="${item.view}"`
          : `data-category="${item.id}"`;
        return `
          <button class="category-item ${active ? "active" : ""}" type="button" ${target}
            ${item.view ? "" : `aria-pressed="${active}"`}>
            <span aria-hidden="true">${item.glyph}</span><b>${item.label}</b>
          </button>`;
      })
      .join("");
    categoryItems.id = "buy-category-list";
    categoryRail?.setAttribute(
      "aria-label",
      state.context === "business" ? "Wholesale product categories" : "Retail product categories",
    );
    categoryRail?.classList.toggle("expanded", railExpanded);
    const allProductsButton = document.querySelector(".category-toggle[data-category='all']");
    const allProductsActive = selectedCategory === "all";
    allProductsButton.classList.toggle("active", allProductsActive);
    allProductsButton.setAttribute("aria-pressed", String(allProductsActive));
    const categoryMoreButton = document.querySelector("[data-category-more]");
    categoryMoreButton.hidden = railExpanded;
    categoryMoreButton.dataset.action = railExpanded ? "category-less" : "category-more";
    categoryMoreButton.setAttribute("aria-expanded", String(railExpanded));
    categoryMoreButton.querySelector("span").textContent = railExpanded ? "−" : "+";
    categoryMoreButton.querySelector("b").textContent = railExpanded ? "Less" : "More";
    document.querySelector("[data-category-total]").textContent = String(regularCategories.length);
    categoryMoreButton.setAttribute(
      "aria-label",
      railExpanded
        ? `Show fewer ${state.context === "business" ? "Wholesale" : "Retail"} categories`
        : `Show all ${regularCategories.length} ${state.context === "business" ? "Wholesale" : "Retail"} categories in the rail`,
    );
  };

  const selectCategory = (category, { push = true } = {}) => {
    if (!isCategoryAvailable(category)) return;
    discovery().category = category;
    discovery().subcategory = "all";
    discovery().search = "";
    state.categoryRailExpanded[state.context] = false;
    search.value = "";
    clearSearch.hidden = true;
    setUrl({
      category: category === "all" ? null : category,
      sub: null,
      q: null,
      view: null,
    }, push);
    renderCategories();
    renderProducts();
  };

  const renderCatalogueScope = (resultCount) => {
    const selectedCategory = availableCategories().find((category) => category.id === discovery().category);
    const categoryLabel = selectedCategory?.label || (state.context === "business" ? "Best prices" : "For you");
    const subcategories = availableSubcategories();
    catalogueScopeKicker.textContent = state.context === "business" ? "Wholesale category" : "Retail category";
    catalogueScopeTitle.textContent =
      discovery().category === "all"
        ? state.context === "business" ? "All wholesale products" : "All retail products"
        : categoryLabel;
    catalogueScopeCount.textContent = `${resultCount} ${resultCount === 1 ? "product" : "products"}`;
    subcategoryRow.hidden = subcategories.length <= 1;
    subcategoryRow.innerHTML = subcategories.length > 1
      ? [
          { id: "all", label: "All" },
          ...subcategories.map((id) => ({ id, label: subcategoryLabels[id] })),
        ]
          .map(({ id, label }) => {
            const active = discovery().subcategory === id;
            const count = products.filter((product) =>
              productCategory(product) === discovery().category &&
              (id === "all" || productSubcategory(product) === id)
            ).length;
            return `
              <button class="subcategory-chip ${active ? "active" : ""}" type="button"
                data-subcategory="${id}" aria-pressed="${active}">
                <span>${label}</span><b>${count}</b>
              </button>`;
          })
          .join("")
      : "";
  };

  const productSearchText = (product) => {
    const offer = product[state.context];
    if (state.context === "business") {
      return [
        product.title,
        product.brand,
        offer.pack,
        offer.seller,
        offer.sellerType,
        ...(product.tags || []),
        ...offer.packs.flat(),
        ...offer.sellers.flat(),
      ].join(" ").toLowerCase();
    }
    return [
      product.title,
      product.brand,
      offer.pack,
      offer.seller,
      offer.sellerType,
      ...(product.tags || []),
    ].join(" ").toLowerCase();
  };

  const renderProductCard = (product) => {
    const currentCartItem = cart().get(product.id);
    const normalizedCartItem = typeof currentCartItem === "number"
      ? { quantity: currentCartItem, packIndex: 0 }
      : currentCartItem;
    const cardPackIndex = normalizedCartItem?.packIndex || 0;
    const cardQuantity = normalizedCartItem?.quantity || 0;
    const offer = currentOffer(product, cardPackIndex);
    const wholesalePreview = state.context === "personal"
      ? `
          <button class="wholesale-glimpse" type="button" data-wholesale-preview="${product.id}">
            <span>Wholesale ${product.business.unit}</span>
            <small>${product.business.packs[0][1]} · See bulk prices</small>
          </button>`
      : "";
    const cartControl = cardQuantity > 0
      ? `
          <div class="card-stepper" role="group" aria-label="${product.title} quantity">
            <button type="button" data-card-decrease="${product.id}"
              aria-label="Decrease ${product.title} quantity">−</button>
            <b aria-live="polite">${cardQuantity}</b>
            <button type="button" data-card-increase="${product.id}"
              aria-label="Increase ${product.title} quantity">+</button>
          </div>`
      : `<button class="card-add" type="button" data-add="${product.id}">ADD</button>`;
    return `
      <article class="product-card">
        <button class="product-card-open-target" type="button"
          data-product-id="${product.id}" aria-label="View ${product.title}"></button>
        <span class="product-badge">${offer.badge}</span>
        ${productVisual(product)}
        <div class="product-card-body">
          <small>${product.brand}</small>
          <h2>${product.title}</h2>
          <p class="card-variant">${offer.variant}</p>
          <p class="card-pack">${offer.pack} · ${offer.unit}</p>
          <div class="card-price-row ${cardQuantity > 0 ? "has-quantity" : ""}">
            <span class="card-price"><strong>${money(offer.price)}</strong><em>${offer.unit}</em></span>
          </div>
          <span class="card-delivery">
            <svg viewBox="0 0 24 24" aria-hidden="true"><circle cx="12" cy="12" r="9"/><path d="M12 7v6l4 2"/></svg>
            ${offer.commitment.delivery}
          </span>
          <span class="card-fulfilment">
            <b>${offer.seller}</b>
            <small>${offer.sellerType}</small>
          </span>
          <span class="card-route">${offer.commitment.route} · ${offer.commitment.confirmed}</span>
          ${wholesalePreview}
          <div class="card-action-row">${cartControl}</div>
        </div>
      </article>`;
  };

  const renderRelatedProducts = (exactProducts, term) => {
    const currentDiscovery = discovery();
    const shouldShow =
      currentDiscovery.category !== "all" &&
      !term &&
      !hasActiveFilters(state.context) &&
      exactProducts.length < 4;

    if (!shouldShow) {
      relatedProducts.hidden = true;
      relatedProductGrid.innerHTML = "";
      return;
    }

    const priorityIds = state.context === "business"
      ? ["atta", "rice", "oil", "thermal-rolls", "paper-cups", "water"]
      : ["tomato", "milk", "atta", "rice", "oil", "soap"];
    const exactIds = new Set(exactProducts.map((product) => product.id));
    const seen = new Set();
    const candidates = [
      ...priorityIds.map((id) => products.find((product) => product.id === id)),
      ...products,
    ]
      .filter(Boolean)
      .filter((product) => {
        if (
          exactIds.has(product.id) ||
          seen.has(product.id) ||
          productCategory(product) === currentDiscovery.category
        ) {
          return false;
        }
        seen.add(product.id);
        return true;
      })
      .slice(0, 3);

    relatedProducts.hidden = candidates.length === 0;
    relatedKicker.textContent = state.context === "business" ? "For this order" : "Popular nearby";
    relatedTitle.textContent = state.context === "business" ? "Commonly ordered together" : "You may also need";
    relatedProductGrid.innerHTML = candidates.map(renderProductCard).join("");
  };

  const offerUnitPrice = (offer) => {
    const match = String(offer.unit || "").replaceAll(",", "").match(/[\d.]+/);
    return match ? Number(match[0]) : Number(offer.price) || Number.MAX_SAFE_INTEGER;
  };

  const deliveryPriority = (delivery) => {
    const value = String(delivery || "").toLowerCase();
    const minutes = value.match(/(\d+)\s*minute/);
    if (minutes) return Number(minutes[1]);
    if (/same day|today/.test(value)) return 720;
    if (/tomorrow|next day|one day/.test(value)) return 1440;
    if (/two days|2 days/.test(value)) return 2880;
    return 10000;
  };

  const catalogueFilterMatch = (product) => {
    const surface = state.context;
    const filters = state.filters[surface];
    const offer = product[surface];
    const delivery = String(offer.delivery || "");
    const sellerText = [
      offer.seller,
      offer.sellerType,
      ...(offer.sellers || []).flat(),
    ].join(" ");
    const termsText = [
      offer.returnTerm,
      ...(offer.terms || []).flat(),
      ...(offer.packs || []).flat(),
      sellerText,
    ].join(" ");

    const timingMatch =
      filters.timing === "anytime" ||
      (filters.timing === "fast" &&
        (surface === "personal"
          ? /minute|today/i.test(delivery)
          : /same day|today|tomorrow|next day|one day/i.test(delivery))) ||
      (filters.timing === "today" && /minute|today|same day/i.test(delivery)) ||
      (filters.timing === "two-days" &&
        /same day|today|tomorrow|next day|one day|two days|2 days/i.test(delivery));

    const termMatch =
      !filters.term ||
      (filters.term === "nearby" &&
        /retailer|shop|km away|nearby/i.test(`${sellerText} ${offer.location || ""}`)) ||
      (filters.term === "returnable" &&
        /return|replacement|refund/i.test(termsText)) ||
      (filters.term === "freight-included" &&
        /freight.*included|freight.*free|free above/i.test(termsText)) ||
      (filters.term === "flexible-moq" &&
        /MOQ\s*[12](?:\D|$)|flexible MOQ/i.test(termsText)) ||
      (filters.term === "manufacturer" &&
        /manufacturer|producer group/i.test(sellerText));

    return timingMatch && termMatch;
  };

  const filteredCatalogueProducts = () => {
    const currentDiscovery = discovery();
    const term = currentDiscovery.search.trim().toLowerCase();
    const matches = products.filter((product) => {
      const categoryMatch =
        currentDiscovery.category === "all" ||
        productCategory(product) === currentDiscovery.category;
      const subcategoryMatch =
        currentDiscovery.subcategory === "all" ||
        productSubcategory(product) === currentDiscovery.subcategory;
      const termMatch = !term || productSearchText(product).includes(term);
      return categoryMatch && subcategoryMatch && termMatch && catalogueFilterMatch(product);
    });
    const filters = state.filters[state.context];
    return matches.sort((left, right) => {
      if (filters.price === "lowest-delivered" || filters.price === "lowest-wholesale") {
        return offerUnitPrice(left[state.context]) - offerUnitPrice(right[state.context]);
      }
      if (filters.timing === "fast") {
        return deliveryPriority(left[state.context].delivery)
          - deliveryPriority(right[state.context].delivery);
      }
      return 0;
    });
  };

  const renderProducts = () => {
    const currentDiscovery = discovery();
    const term = currentDiscovery.search.trim().toLowerCase();
    const filtered = filteredCatalogueProducts();

    renderCatalogueScope(filtered.length);
    renderHouseholdBasketOffer();
    const compactRail = window.innerWidth <= 350;
    const railProductLimit = state.categoryRailExpanded[state.context]
      ? compactRail ? 2 : 4
      : compactRail ? 1 : 2;
    const railProducts = filtered.slice(0, railProductLimit);
    const wideProducts = filtered.slice(railProductLimit);
    productGrid.innerHTML = railProducts.map(renderProductCard).join("");
    productGridWide.innerHTML = wideProducts.map(renderProductCard).join("");
    productGridWide.hidden = wideProducts.length === 0;

    emptyResults.hidden = filtered.length > 0;
    productGrid.hidden = railProducts.length === 0;
    alignCategoryRail(categoryRail, catalogueResults);
    renderRelatedProducts(filtered, term);
    renderFilterStatus(state.context);
  };

  const renderContext = () => {
    document.querySelectorAll("[data-context]").forEach((button) => {
      const active = button.dataset.context === state.context;
      button.classList.toggle("active", active);
      button.setAttribute("aria-selected", String(active));
    });

    document.querySelector("[data-workspace-strip]").hidden = state.context !== "business";
    renderLocation();
    document.querySelector("[data-catalogue-kicker]").textContent =
      state.context === "business" ? "Wholesale packs · business prices" : "Retail packs";
    document.querySelector("[data-catalogue-title]").textContent =
      state.context === "business" ? "Wholesale prices" : "Recommended near you";
    document.querySelector("[data-basket-pill-label]").textContent =
      state.context === "business" ? "Bulk order" : "Cart";
    document.querySelector("[data-basket-pill-copy]").textContent =
      state.context === "business" ? "Review bulk order" : "View cart";
    document.querySelector("[data-action='saved']").setAttribute(
      "aria-label",
      state.context === "business" ? "Saved bulk orders" : "Saved items",
    );
    search.value = discovery().search;
    search.placeholder = state.context === "business"
      ? "Search bulk products"
      : "Search products or brands";
    clearSearch.hidden = !discovery().search;
    renderCategories();
    state.selectedPack = 0;
    state.quantity = minimumQuantity(state.currentProduct, 0);
    renderProducts();
    updateCartSurfaces();
    if (visibleView() === "product") renderProduct();
    if (visibleView() === "basket") renderBasket();
    app.dataset.buyContext = state.context;
    setDock(visibleView());
    renderLiveOrderStatus(visibleView());
  };

  const setContext = (context, { push = true } = {}) => {
    if (!["personal", "business"].includes(context)) return;
    if (context === state.context) return;
    const previousView = visibleView();
    const directionClass = context === "business" ? "context-next" : "context-previous";
    clearTimeout(contextMotionTimer);
    app.classList.remove("context-changing", "context-next", "context-previous");
    app.classList.add("context-changing", directionClass);
    state.context = context;
    setUrl({
      context: context === "personal" ? null : "business",
      category: discovery().category === "all" ? null : discovery().category,
      sub: discovery().subcategory === "all" ? null : discovery().subcategory,
      q: discovery().search || null,
    }, push);
    renderContext();
    if (previousView === "medicine" || previousView === "checkout" || previousView === "confirmed") {
      showView("catalogue", { push: false });
    }
    hapticTick();
    showToast(context === "business" ? "Wholesale prices opened" : "Retail prices opened");
    contextMotionTimer = setTimeout(() => {
      app.classList.remove("context-changing", "context-next", "context-previous");
    }, 260);
  };

  const renderProduct = () => {
    const product = state.currentProduct;
    const baseOffer = product[state.context];
    const offer = currentOffer();
    document.querySelector("[data-product-art]").innerHTML = art[product.visual];
    document.querySelector("[data-product-context]").textContent =
      state.context === "business" ? "Wholesale" : "Retail";
    document.querySelector("[data-product-brand]").textContent = product.brand;
    document.querySelector("[data-product-title]").textContent = product.title;
    document.querySelector("[data-product-pack]").textContent = offer.pack;
    document.querySelector("[data-product-stock]").textContent = offer.stock;
    document.querySelector("[data-product-specs]").innerHTML = [
      ["Variant", offer.variant],
      ["Selected pack", offer.pack],
      ["Net quantity", offer.packFacts.netPerPack],
      ["Unit price", offer.unit],
      [state.context === "business" ? "Minimum order" : "Minimum", state.context === "business"
        ? `${offer.packFacts.minimum} trade packs`
        : "1 pack"],
      ["Order quantity", `<span data-product-order-quantity>${packFacts(
        product,
        state.selectedPack,
        state.quantity,
      ).ordered}</span>`],
    ]
      .map(
        ([label, value]) =>
          `<span class="product-spec"><small>${label}</small><strong>${value}</strong></span>`,
      )
      .join("");
    document.querySelector("[data-offer-label]").textContent =
      state.context === "business" ? "Landed price for selected pack" : "Final delivered price";
    document.querySelector("[data-offer-price]").textContent = money(offer.price);
    document.querySelector("[data-offer-unit]").textContent = offer.unit;
    document.querySelector("[data-offer-reason]").textContent = offer.badge;
    document.querySelector("[data-offer-seller]").textContent = offer.seller;
    document.querySelector("[data-offer-seller-type]").textContent = offer.sellerType;
    document.querySelector("[data-seller-avatar]").textContent = offer.seller.split(" ").map((word) => word[0]).slice(0, 2).join("");
    document.querySelector("[data-protection-note]").textContent = product.protection;
    document.querySelector("[data-protection-title]").textContent =
      state.context === "business" ? "Order terms protected" : "Purchase protected";

    document.querySelector("[data-pack-choice]").innerHTML = baseOffer.packs
      .map(
        ([name, note], index) => {
          const packOffer = currentOffer(product, index);
          const choiceNote = state.context === "business"
            ? `${note} · ${money(packOffer.price)} · ${packOffer.unit}`
            : `${money(packOffer.price)} · ${packOffer.unit}`;
          return `
          <button class="pack-option ${state.selectedPack === index ? "active" : ""}" type="button" role="radio"
            aria-checked="${state.selectedPack === index}" data-pack-index="${index}">
            <strong>${name}</strong><span>${choiceNote}</span>
          </button>`;
        },
      )
      .join("");

    document.querySelector("[data-offer-facts]").innerHTML = [
      ["Availability", offer.stock],
      ["Seller", offer.sellerType],
      ["Deliver to", `${offer.commitment.destination.city} ${offer.commitment.destination.pin}`],
      ["Returns", offer.returnTerm],
    ]
      .map(([label, value]) => `<span class="offer-fact"><small>${label}</small><strong>${value}</strong></span>`)
      .join("");

    document.querySelector("[data-commitment-delivery]").textContent = offer.commitment.delivery;
    document.querySelector("[data-commitment-status]").textContent = offer.commitment.confirmed;
    document.querySelector("[data-delivery-commitment]").innerHTML = [
      ["From", `${offer.commitment.origin.city}, ${offer.commitment.origin.state} ${offer.commitment.origin.pin}`],
      ["Deliver to", `${offer.commitment.destination.city}, ${offer.commitment.destination.state} ${offer.commitment.destination.pin}`],
      ["Order by", offer.commitment.orderBy],
      ["Dispatch", offer.commitment.dispatch],
    ]
      .map(
        ([label, value]) =>
          `<span><small>${label}</small><strong>${value}</strong></span>`,
      )
      .join("");
    document.querySelector("[data-commitment-note]").textContent = offer.commitment.note;

    const businessTerms = document.querySelector("[data-business-terms]");
    businessTerms.hidden = state.context !== "business";
    if (state.context === "business") {
      const priceScale = baseOffer.price ? offer.price / baseOffer.price : 1;
      document.querySelector("[data-price-breaks]").innerHTML = offer.breaks
        .map(
          ([range, price], index) =>
            `<span class="price-break ${index === 0 ? "active" : ""}"><small>${range}</small><strong>${scaleMoneyLabel(price, priceScale)}</strong></span>`,
        )
        .join("");
      document.querySelector("[data-term-grid]").innerHTML = offer.terms
        .map(([label, value]) => `<span class="term-item"><small>${label}</small><strong>${value}</strong></span>`)
        .join("");
    }

    updateQuantity();
  };

  const openProduct = (id, { push = true } = {}) => {
    const product = products.find((item) => item.id === id);
    if (!product) return;
    if (visibleView() === "catalogue") {
      state.catalogueScroll[state.context] = window.scrollY;
    }
    const existing = cart().get(id);
    const normalizedExisting = typeof existing === "number"
      ? { quantity: existing, packIndex: 0 }
      : existing;
    state.currentProduct = product;
    state.selectedPack = normalizedExisting?.packIndex || 0;
    state.quantity = normalizedExisting?.quantity
      || minimumQuantity(product, state.selectedPack);
    setUrl({ product: id }, push);
    renderProduct();
    showView("product", { push: false });
  };

  const updateQuantity = () => {
    const offer = currentOffer();
    const unitName = state.context === "business"
      ? (state.quantity === 1 ? "trade pack" : "trade packs")
      : (state.quantity === 1 ? "pack" : "packs");
    document.querySelector("[data-quantity]").textContent = String(state.quantity);
    document.querySelector("[data-quantity-label]").textContent = `${state.quantity} ${unitName}`;
    document.querySelector("[data-add-detail-price]").textContent = money(offer.price * state.quantity);
    const orderQuantity = document.querySelector("[data-product-order-quantity]");
    if (orderQuantity) {
      orderQuantity.textContent = packFacts(
        state.currentProduct,
        state.selectedPack,
        state.quantity,
      ).ordered;
    }
    const updatingExistingLine = cart().has(state.currentProduct.id);
    document.querySelector("[data-add-detail-label]").textContent = state.context === "business"
      ? (updatingExistingLine ? "Update bulk order" : "Add to bulk order")
      : (updatingExistingLine ? "Update cart" : "Add to cart");
    const orderShortcut = document.querySelector("[data-product-order-shortcut]");
    const orderStats = cartStats();
    orderShortcut.hidden = orderStats.count === 0;
    document.querySelector("[data-product-order-shortcut-label]").textContent =
      state.context === "business" ? "View bulk order" : "View cart";
    document.querySelector("[data-product-order-shortcut-total]").textContent =
      money(orderStats.total);
  };

  const cart = (context = state.context) => state.carts[context];

  const inBuyContext = (context, callback) => {
    const previousContext = state.context;
    state.context = context;
    try {
      return callback();
    } finally {
      state.context = previousContext;
    }
  };

  const cloneOrder = (source) =>
    new Map(
      [...source.entries()].map(([id, item]) => [
        id,
        typeof item === "number" ? item : { ...item },
      ]),
    );

  const reorderLines = (order) => {
    if (order?.kind === "medicine") {
      return new Map([
        [medicineCartKey("paracetamol-500"), {
          kind: "medicine",
          quantity: 1,
          packIndex: 0,
        }],
        [medicineCartKey("ors-hydration"), {
          kind: "medicine",
          quantity: 2,
          packIndex: 0,
        }],
      ]);
    }
    return cloneOrder(state.lastOrders[order?.context || state.context]);
  };

  const openReorder = (order = findOrder()) => {
    state.context = order.context;
    state.addressConfirmationKey = null;
    state.carts[state.context] = reorderLines(order);
    state.cartReturnView = order.kind === "medicine"
      ? "medicine"
      : state.context === "business" ? "wholesale" : "retail";
    state.cartScope = order.kind === "medicine"
      ? "medicine"
      : state.context === "business" ? "wholesale" : "shop";
    setUrl({ context: state.context === "business" ? "business" : null }, false);
    updateCartSurfaces();
    renderProducts();
    showView("basket");
    showToast(
      order.kind === "medicine"
        ? "Medicines are ready to review"
        : state.context === "business"
          ? "Previous supplies are ready to edit"
          : "Previous products are ready to edit",
    );
  };

  const medicineCartKey = (id) => `medicine:${id}`;
  const medicineByCartKey = (id) =>
    [...medicineProducts, prescriptionQuoteProduct]
      .find((product) => medicineCartKey(product.id) === id);
  const medicineCommitment = (product) => {
    const today = new Date();
    const deliveryDay = new Date(today);
    deliveryDay.setHours(0, 0, 0, 0);
    const afterCutoff = today.getHours() >= 18;
    if (afterCutoff) deliveryDay.setDate(deliveryDay.getDate() + 1);
    return {
      origin: { city: "Jodhpur", state: "Rajasthan", pin: "342001" },
      destination: destinationFor("personal"),
      route: "Jodhpur → Jodhpur 342003",
      orderBy: afterCutoff ? `${dayLabel(deliveryDay)} · 6:00 pm` : "Today · 6:00 pm",
      dispatch: dayLabel(deliveryDay),
      delivery: `${dayLabel(deliveryDay)} · by ${afterCutoff ? "11:00 am" : "8:30 pm"}`,
      deliveryStart: deliveryDay.getTime(),
      deliveryEnd: deliveryDay.getTime(),
      card: `Jodhpur → Jodhpur · ${dayLabel(deliveryDay, false)}`,
      confirmed: `Confirmed ${dayLabel(today, false)}`,
      note: `${product.seller} confirmed the selected pack and delivery to 342003.`,
    };
  };

  const medicineCategoryMatches = (product, category) =>
    category === "all" ||
    (category === "rx" && product.prescriptionRequired) ||
    product.category === category;

  const medicineCategoryCount = (category) =>
    medicineProducts.filter((product) => medicineCategoryMatches(product, category)).length;

  const medicineManufacturerFulfilled = (product) =>
    !product.prescriptionRequired && [
      "vitamins",
      "first-aid",
      "devices",
      "baby-care",
      "skin-care",
    ].includes(product.category);

  const medicineDeliveryPriority = (product) => {
    if (/Sardarpura/i.test(product.seller)) return 20;
    if (/Jodhpur Care/i.test(product.seller)) return 35;
    if (/Marwar/i.test(product.seller)) return 55;
    return medicineManufacturerFulfilled(product) ? 90 : 75;
  };

  const medicineFilterMatch = (product) => {
    const filters = state.filters.medicine;
    const commitment = medicineCommitment(product);
    const today = new Date();
    today.setHours(23, 59, 59, 999);
    const timingMatch =
      filters.timing === "anytime" ||
      (filters.timing === "fast" && medicineDeliveryPriority(product) <= 55) ||
      (filters.timing === "today" && commitment.deliveryEnd <= today.getTime());
    const termMatch =
      !filters.term ||
      (filters.term === "otc" && !product.prescriptionRequired) ||
      (filters.term === "nearby-pharmacy" && !medicineManufacturerFulfilled(product)) ||
      (filters.term === "manufacturer" && medicineManufacturerFulfilled(product));
    return timingMatch && termMatch;
  };

  const filteredMedicineProducts = () => {
    const term = medicineSearch.value.trim().toLowerCase();
    const category = state.medicineCategory;
    const filters = state.filters.medicine;
    const matching = medicineProducts.filter((product) => {
      const categoryMatch = medicineCategoryMatches(product, category);
      const termMatch = !term || [
        product.title,
        product.brand,
        product.composition,
        product.pack,
        product.category,
        product.note,
        product.seller,
      ].join(" ")
        .toLowerCase()
        .includes(term);
      return categoryMatch && termMatch && medicineFilterMatch(product);
    });
    return matching.sort((left, right) => {
      if (filters.price === "lowest-delivered") return left.price - right.price;
      if (filters.timing === "fast") {
        return medicineDeliveryPriority(left) - medicineDeliveryPriority(right);
      }
      return 0;
    });
  };

  const medicineVisual = (product) => {
    const label = product.label || product.brand;
    const common = `style="--medicine-accent:${product.accent};--medicine-soft:${product.soft}"`;
    const visuals = {
      box: `
        <svg viewBox="0 0 124 104" aria-hidden="true">
          <ellipse cx="62" cy="90" rx="34" ry="7" fill="rgba(24,24,54,.12)"/>
          <path d="M31 19h62v65H31z" fill="#fff" stroke="var(--medicine-accent)" stroke-width="2"/>
          <path d="M31 19h62v16H31z" fill="var(--medicine-accent)"/>
          <path d="M39 45h46M39 52h32" stroke="var(--medicine-accent)" stroke-width="3" stroke-linecap="round"/>
          <circle cx="77" cy="68" r="10" fill="var(--medicine-soft)"/>
          <path d="M72 68h10M77 63v10" stroke="var(--medicine-accent)" stroke-width="2"/>
          <text x="39" y="73" fill="#11112b" font-size="10" font-weight="800">${label}</text>
        </svg>`,
      bottle: `
        <svg viewBox="0 0 124 104" aria-hidden="true">
          <ellipse cx="62" cy="91" rx="29" ry="7" fill="rgba(24,24,54,.12)"/>
          <path d="M48 14h28v13H48z" fill="var(--medicine-accent)"/>
          <path d="M44 27h36l5 12v43c0 5-4 8-8 8H47c-4 0-8-3-8-8V39z" fill="#fff" stroke="var(--medicine-accent)" stroke-width="2"/>
          <path d="M39 47h46v27H39z" fill="var(--medicine-soft)"/>
          <text x="62" y="62" text-anchor="middle" fill="#11112b" font-size="10" font-weight="800">${label}</text>
        </svg>`,
      tube: `
        <svg viewBox="0 0 124 104" aria-hidden="true">
          <ellipse cx="62" cy="91" rx="31" ry="7" fill="rgba(24,24,54,.12)"/>
          <path d="M38 20h48l-7 63H45z" fill="#fff" stroke="var(--medicine-accent)" stroke-width="2"/>
          <path d="M38 20h48l-2 17H40z" fill="var(--medicine-accent)"/>
          <path d="M48 47h28v22H48z" fill="var(--medicine-soft)"/>
          <text x="62" y="61" text-anchor="middle" fill="#11112b" font-size="9" font-weight="800">${label}</text>
          <path d="M46 83h32v7H46z" fill="var(--medicine-accent)"/>
        </svg>`,
      sachet: `
        <svg viewBox="0 0 124 104" aria-hidden="true">
          <ellipse cx="62" cy="91" rx="34" ry="7" fill="rgba(24,24,54,.12)"/>
          <path d="M34 17h56l-5 69H39z" fill="#fff" stroke="var(--medicine-accent)" stroke-width="2"/>
          <path d="M34 17h56v14H34z" fill="var(--medicine-accent)"/>
          <circle cx="62" cy="57" r="20" fill="var(--medicine-soft)"/>
          <text x="62" y="61" text-anchor="middle" fill="#11112b" font-size="10" font-weight="800">${label}</text>
        </svg>`,
      inhaler: `
        <svg viewBox="0 0 124 104" aria-hidden="true">
          <ellipse cx="64" cy="91" rx="30" ry="7" fill="rgba(24,24,54,.12)"/>
          <path d="M49 16h28v43H49z" rx="5" fill="#fff" stroke="var(--medicine-accent)" stroke-width="2"/>
          <path d="M45 55h39v28H45z" fill="var(--medicine-accent)"/>
          <path d="M84 66h17v17H73" fill="var(--medicine-soft)" stroke="var(--medicine-accent)" stroke-width="2"/>
          <text x="63" y="44" text-anchor="middle" fill="#11112b" font-size="9" font-weight="800">${label}</text>
        </svg>`,
      spray: `
        <svg viewBox="0 0 124 104" aria-hidden="true">
          <ellipse cx="62" cy="91" rx="27" ry="7" fill="rgba(24,24,54,.12)"/>
          <path d="M50 34h27l5 12v36c0 5-4 8-8 8H53c-4 0-8-3-8-8V46z" fill="#fff" stroke="var(--medicine-accent)" stroke-width="2"/>
          <path d="M54 19h22v15H54zM76 22h20v8H76z" fill="var(--medicine-accent)"/>
          <path d="M45 53h37v21H45z" fill="var(--medicine-soft)"/>
          <text x="63" y="67" text-anchor="middle" fill="#11112b" font-size="8" font-weight="800">${label}</text>
        </svg>`,
      device: `
        <svg viewBox="0 0 124 104" aria-hidden="true">
          <ellipse cx="62" cy="91" rx="37" ry="7" fill="rgba(24,24,54,.12)"/>
          <rect x="27" y="17" width="70" height="67" rx="13" fill="#fff" stroke="var(--medicine-accent)" stroke-width="2"/>
          <rect x="38" y="29" width="48" height="25" rx="6" fill="var(--medicine-soft)"/>
          <text x="62" y="45" text-anchor="middle" fill="#11112b" font-size="11" font-weight="900">${label}</text>
          <circle cx="48" cy="68" r="5" fill="var(--medicine-accent)"/>
          <path d="M60 68h23" stroke="var(--medicine-accent)" stroke-width="4" stroke-linecap="round"/>
        </svg>`,
    };
    return `
      <span class="medicine-product-photo" role="img" aria-label="${product.brand} ${product.pack}" ${common}>
        ${visuals[product.visual] || visuals.box}
      </span>`;
  };

  const renderMedicineCategories = () => {
    const compactLimit = 5;
    const expanded = state.medicineCategoryRailExpanded;
    let visibleCategories = expanded
      ? medicineCategorySet
      : medicineCategorySet.slice(0, compactLimit);
    if (!expanded && state.medicineCategory !== "all") {
      const selected = medicineCategorySet.find((item) => item.id === state.medicineCategory);
      if (selected && !visibleCategories.some((item) => item.id === selected.id)) {
        visibleCategories = [...visibleCategories.slice(0, compactLimit - 1), selected];
      }
    }
    medicineCategoryItems.innerHTML = visibleCategories
      .map((item) => {
        const active = item.id === state.medicineCategory;
        return `
          <button class="category-item ${active ? "active" : ""}" type="button"
            data-medicine-category="${item.id}" aria-pressed="${active}">
            <span aria-hidden="true">${item.glyph}</span>
            <b>${item.label}</b>
            <i>${medicineCategoryCount(item.id)}</i>
          </button>`;
      })
      .join("");
    const allButton = medicineCategoryRail.querySelector("[data-medicine-category='all']");
    const allActive = state.medicineCategory === "all";
    allButton.classList.toggle("active", allActive);
    allButton.setAttribute("aria-pressed", String(allActive));
    medicineCategoryRail.classList.toggle("expanded", expanded);
    medicineCategoryMore.hidden = expanded;
    medicineCategoryMore.dataset.action = expanded
      ? "medicine-category-less"
      : "medicine-category-more";
    medicineCategoryMore.setAttribute("aria-expanded", String(expanded));
    medicineCategoryMore.setAttribute(
      "aria-label",
      expanded
        ? "Show fewer Medicine categories"
        : `Show all ${medicineCategorySet.length} Medicine categories in the rail`,
    );
    medicineCategoryMore.querySelector("span").textContent = expanded ? "−" : "+";
    medicineCategoryMore.querySelector("b").textContent = expanded ? "Less" : "More";
    medicineCategoryTotal.textContent = String(medicineCategorySet.length);
  };

  const renderMedicineCard = (product) => {
    const key = medicineCartKey(product.id);
    const line = state.carts.personal.get(key);
    const quantity = line?.quantity || 0;
    const categoryName =
      medicineCategorySet.find((item) => item.id === product.category)?.label ||
      "Health";
    const saving = Math.max(0, product.mrp - product.price);
    const savingPercent = Math.round((saving / product.mrp) * 100);
    const commitment = medicineCommitment(product);
    const prescriptionApproved = state.rxApprovedProductIds.has(product.id);
    const prescriptionReviewing = product.prescriptionRequired
      && state.prescriptionMatchedProductIds.has(product.id)
      && state.prescriptionState === "review";
    const manufacturerFulfilment = medicineManufacturerFulfilled(product);
    const fulfilmentName = manufacturerFulfilment ? product.brand : product.seller;
    const fulfilmentType = manufacturerFulfilment ? "Manufacturer" : "Licensed pharmacy";
    return `
      <article class="medicine-product-card">
        <button class="medicine-product-open" type="button"
          data-medicine-product-id="${product.id}"
          aria-label="View ${product.title} details">
          <span class="medicine-product-badge ${product.prescriptionRequired ? "rx" : "otc"}">
            ${prescriptionApproved
              ? "Prescription verified"
              : product.prescriptionRequired ? "Prescription required" : `${savingPercent}% off`}
          </span>
          ${medicineVisual(product)}
          <span class="medicine-product-copy">
            <small>${categoryName} · ${product.brand}</small>
            <strong>${product.title}</strong>
            <em>${product.composition}</em>
            <span>${product.pack}</span>
          </span>
          <span class="medicine-detail-cue">Details <b aria-hidden="true">›</b></span>
        </button>
        <span class="medicine-delivery">
          <svg viewBox="0 0 24 24" aria-hidden="true"><circle cx="12" cy="12" r="9"/><path d="M12 7v6l4 2"/></svg>
          <b>${commitment.delivery}</b>
          <small><strong>${fulfilmentName}</strong> · ${fulfilmentType}</small>
          <em>${product.note}</em>
        </span>
        <span class="medicine-product-buy">
          <span class="medicine-price"><strong>${money(product.price)}</strong><del>${money(product.mrp)}</del></span>
          <small>${product.unit}</small>
          ${product.prescriptionRequired
            ? prescriptionApproved
              ? quantity
                ? `<span class="medicine-stepper" role="group" aria-label="${product.title} quantity">
                    <button type="button" data-medicine-decrease="${product.id}" aria-label="Decrease ${product.title} quantity">−</button>
                    <b>${quantity}</b>
                    <button type="button" data-medicine-increase="${product.id}" aria-label="Increase ${product.title} quantity">+</button>
                  </span>`
                : `<button type="button" data-medicine-add="${product.id}">ADD</button>`
              : prescriptionReviewing
                ? `<button class="medicine-rx-action" type="button" data-action="prescription-status">Reviewing</button>`
                : `<button class="medicine-rx-action" type="button"
                data-action="past-prescriptions" data-rx-product="${product.id}">
                Use Rx
              </button>`
            : quantity
            ? `<span class="medicine-stepper" role="group" aria-label="${product.title} quantity">
                <button type="button" data-medicine-decrease="${product.id}" aria-label="Decrease ${product.title} quantity">−</button>
                <b>${quantity}</b>
                <button type="button" data-medicine-increase="${product.id}" aria-label="Increase ${product.title} quantity">+</button>
              </span>`
            : `<button type="button" data-medicine-add="${product.id}">ADD</button>`}
        </span>
      </article>`;
  };

  const renderMedicine = () => {
    const coverageProducts = prescriptionCoverageProducts();
    const coverageCount = coverageProducts.length;
    savedRxNote.textContent = state.selectedSavedPrescription
      ? `${coverageCount} ${coverageCount === 1 ? "medicine" : "medicines"} linked`
      : "2 saved prescriptions";
    pharmacistNote.textContent = state.pharmacistState === "requested"
      ? "Call requested · under 2 min"
      : "Available now · under 2 min";
    refillNote.textContent = state.refillState === "active"
      ? "Reminder set · confirm before order"
      : "Next refill due 11 Aug";
    const term = medicineSearch.value.trim().toLowerCase();
    const category = state.medicineCategory;
    const matching = filteredMedicineProducts();
    renderMedicineCategories();
    const categoryLabel = medicineCategorySet.find((item) => item.id === category)?.label;
    medicineResultsTitle.textContent = term
      ? `Results for “${medicineSearch.value.trim()}”`
      : category === "all"
        ? "Medicines and health products"
        : categoryLabel || "Medicines and health products";
    medicineScopeCount.textContent =
      `${matching.length} ${matching.length === 1 ? "product" : "products"}`;
    const compactRail = window.innerWidth <= 350;
    const railProductLimit = state.medicineCategoryRailExpanded
      ? compactRail ? 2 : 4
      : compactRail ? 1 : 2;
    const railProducts = matching.slice(0, railProductLimit);
    const wideProducts = matching.slice(railProductLimit);
    medicineResults.innerHTML = matching.length
      ? railProducts.map(renderMedicineCard).join("")
      : `<div class="medicine-empty">
          <strong>No matching products found</strong>
          <span>Try another medicine, brand or health category.</span>
          <button type="button" data-action="pharmacist">Ask a pharmacist</button>
        </div>`;
    medicineResultsWide.innerHTML = wideProducts.map(renderMedicineCard).join("");
    medicineResultsWide.hidden = wideProducts.length === 0;
    renderFilterStatus("medicine");
    prescriptionCard.hidden = state.prescriptionState === "none";
    prescriptionCard.classList.toggle(
      "is-review",
      state.prescriptionState === "review",
    );
    prescriptionCard.classList.toggle(
      "is-approved",
      state.prescriptionState === "quoted",
    );
    if (state.prescriptionState !== "none") {
      document.querySelector("[data-prescription-kicker]").textContent =
        state.prescriptionState === "quoted" ? "Prescription verified" : "Prescription linked";
      document.querySelector("[data-prescription-title]").textContent =
        state.prescriptionState === "quoted"
          ? `${coverageCount} ${coverageCount === 1 ? "medicine is" : "medicines are"} ready`
          : `${coverageCount} ${coverageCount === 1 ? "medicine" : "medicines"} under review`;
      document.querySelector("[data-prescription-note]").textContent =
        state.prescriptionState === "quoted"
          ? "Use ADD on every verified medicine. No repeat upload."
          : "One pharmacist review covers every medicine listed on this prescription.";
      document.querySelector("[data-prescription-coverage]").textContent =
        `${coverageCount} linked`;
    }
    alignCategoryRail(medicineCategoryRail, medicineCatalogueResults);
  };

  const addMedicineToCart = (id) => {
    const product = medicineProducts.find((item) => item.id === id);
    if (!product) return;
    if (product.prescriptionRequired && !state.rxApprovedProductIds.has(product.id)) {
      state.prescriptionProduct = product.id;
      openSheet("past-prescriptions");
      return;
    }
    const key = medicineCartKey(id);
    const existing = state.carts.personal.get(key);
    state.carts.personal.set(key, {
      kind: "medicine",
      quantity: (existing?.quantity || 0) + 1,
      packIndex: 0,
      prescriptionVerified:
        Boolean(existing?.prescriptionVerified)
        || (product.prescriptionRequired && state.rxApprovedProductIds.has(product.id)),
    });
    state.addressConfirmationKey = null;
    state.cartScope = availableCartScopes().length > 1 ? "all" : "medicine";
    announceCartAddition(product.title);
    renderMedicine();
  };

  const cartCommitmentLines = (context = state.context) =>
    inBuyContext(context, () => [...cart(context).entries()]
      .map(([id, item]) => {
        if (item?.kind === "household-basket") {
          const details = householdBasketDetails(item.basketId, item.members);
          if (!details) return null;
          return {
            id,
            isHouseholdBasket: true,
            details,
            product: {
              id,
              title: details.title,
              visual: "atta",
            },
            normalized: {
              ...item,
              quantity: 1,
              packIndex: 0,
            },
            offer: {
              price: details.price,
              seller: details.seller,
              sellerType: details.sellerType,
              variant: `${details.members} members · ${details.duration}`,
              pack: `${details.itemCount} products · ${details.packCount} packs`,
              unit: `Save ${money(details.saving)}`,
              commitment: details.commitment,
            },
          };
        }
        const medicineProduct = context === "personal" ? medicineByCartKey(id) : null;
        if (item?.kind === "medicine" && medicineProduct) {
          const normalized = {
            ...item,
            quantity: Math.max(1, Number(item.quantity) || 1),
            packIndex: 0,
          };
          return {
            id,
            isMedicine: true,
            product: {
              id,
              title: medicineProduct.title,
              visual: "soap",
              medicineGlyph: medicineProduct.label || "Rx",
            },
            normalized,
            offer: {
              price: medicineProduct.price,
              seller: medicineProduct.seller,
              sellerType: "Licensed pharmacy",
              variant: medicineProduct.prescriptionRequired
                ? item.prescriptionVerified || state.rxApprovedProductIds.has(medicineProduct.id)
                  ? "Prescription verified"
                  : "Pharmacist review required"
                : medicineProduct.note,
              pack: medicineProduct.pack,
              unit: medicineProduct.unit,
              commitment: medicineCommitment(medicineProduct),
            },
          };
        }
        const product = products.find((candidate) => candidate.id === id);
        if (!product) return null;
        const normalized = typeof item === "number"
          ? { quantity: item, packIndex: 0 }
          : item;
        return {
          id,
          product,
          normalized,
          offer: currentOffer(product, normalized.packIndex),
        };
      })
      .filter(Boolean));

  const commitmentSummaryForLines = (lines, context = state.context) => inBuyContext(context, () => {
    if (!lines.length) {
      return {
        title: state.deliveryChoices[context].title,
        detail: state.deliveryChoices[context].detail,
        supplierCount: 0,
        lines,
      };
    }
    const supplierCount = new Set(lines.map(({ offer }) => offer.seller)).size;
    const windows = [...new Set(lines.map(({ offer }) => offer.commitment.delivery))];
    const earliest = Math.min(...lines.map(({ offer }) => offer.commitment.deliveryStart));
    const latest = Math.max(...lines.map(({ offer }) => offer.commitment.deliveryEnd));
    const title = windows.length === 1
      ? windows[0]
      : `${dayLabel(new Date(earliest))} – ${dayLabel(new Date(latest))}`;
    return {
      title,
      detail: context === "business"
        ? `${supplierCount} ${supplierCount === 1 ? "supplier" : "suppliers"} · dispatch and delivery shown for each`
        : `${supplierCount} ${supplierCount === 1 ? "seller" : "sellers"} · dated delivery shown for every product`,
      supplierCount,
      lines,
    };
  });

  const cartCommitmentSummary = (context = state.context) =>
    commitmentSummaryForLines(cartCommitmentLines(context), context);

  const cartStats = (context = state.context) => inBuyContext(context, () => {
    let count = 0;
    let subtotal = 0;
    cart(context).forEach((item, id) => {
      if (item?.kind === "household-basket") {
        const details = householdBasketDetails(item.basketId, item.members);
        if (!details) return;
        count += 1;
        subtotal += details.price;
        return;
      }
      if (item?.kind === "medicine" && context === "personal") {
        const medicineProduct = medicineByCartKey(id);
        if (!medicineProduct) return;
        const quantity = Math.max(1, Number(item.quantity) || 1);
        count += quantity;
        subtotal += medicineProduct.price * quantity;
        return;
      }
      const product = products.find((item) => item.id === id);
      if (!product) return;
      const normalized = typeof item === "number" ? { quantity: item, packIndex: 0 } : item;
      count += normalized.quantity;
      subtotal += currentOffer(product, normalized.packIndex).price * normalized.quantity;
    });
    const selectedFee = state.deliveryChoices[context].fee;
    const defaultDelivery = context === "business"
      ? (subtotal >= 5000 ? 0 : 180)
      : (subtotal >= 499 ? 0 : 24);
    const delivery = count === 0 ? 0 : selectedFee === null ? defaultDelivery : selectedFee;
    return { count, subtotal, delivery, total: subtotal + delivery };
  });

  const personalCartLines = () => cartCommitmentLines("personal");
  const shopCartLines = () => personalCartLines().filter((line) => !line.isMedicine);
  const medicineCartLines = () => personalCartLines().filter((line) => line.isMedicine);
  const wholesaleCartLines = () => cartCommitmentLines("business");

  const cartStatsForLines = (lines, context) => {
    const count = lines.reduce(
      (total, line) => total + (line.isHouseholdBasket ? 1 : line.normalized.quantity),
      0,
    );
    const subtotal = lines.reduce(
      (total, line) => total + (
        line.isHouseholdBasket
          ? line.details.price
          : line.offer.price * line.normalized.quantity
      ),
      0,
    );
    const selectedFee = state.deliveryChoices[context].fee;
    const defaultDelivery = context === "business"
      ? (subtotal >= 5000 ? 0 : 180)
      : (subtotal >= 499 ? 0 : 24);
    const delivery = count === 0 ? 0 : selectedFee === null ? defaultDelivery : selectedFee;
    return { count, subtotal, delivery, total: subtotal + delivery };
  };

  const cartScopeLines = (scope) => {
    if (scope === "shop") return shopCartLines();
    if (scope === "medicine") return medicineCartLines();
    if (scope === "wholesale") return wholesaleCartLines();
    return [...personalCartLines(), ...wholesaleCartLines()];
  };

  const cartScopeStats = (scope) => {
    if (scope === "shop") return cartStatsForLines(shopCartLines(), "personal");
    if (scope === "medicine") return cartStatsForLines(medicineCartLines(), "personal");
    if (scope === "wholesale") return cartStatsForLines(wholesaleCartLines(), "business");
    const personal = cartStatsForLines(personalCartLines(), "personal");
    const wholesale = cartStatsForLines(wholesaleCartLines(), "business");
    return {
      count: personal.count + wholesale.count,
      subtotal: personal.subtotal + wholesale.subtotal,
      delivery: personal.delivery + wholesale.delivery,
      total: personal.total + wholesale.total,
    };
  };

  const availableCartScopes = () =>
    ["shop", "wholesale", "medicine"].filter((scope) => cartScopeStats(scope).count > 0);

  const normalizedCartScope = (scope) =>
    scope === "retail"
      ? "shop"
      : ["all", "shop", "wholesale", "medicine"].includes(scope) ? scope : null;

  const clearCartScope = (scope) => {
    if (scope === "all") {
      cart("personal").clear();
      cart("business").clear();
      return;
    }
    if (scope === "wholesale") {
      cart("business").clear();
      return;
    }
    const removeMedicine = scope === "medicine";
    [...cart("personal").entries()].forEach(([id, item]) => {
      const medicine = item?.kind === "medicine" || Boolean(medicineByCartKey(id));
      if (medicine === removeMedicine) cart("personal").delete(id);
    });
  };

  const cloneCartScope = (scope) => {
    if (scope === "wholesale") return cloneOrder(cart("business"));
    const selected = new Map();
    const includeMedicine = scope === "medicine";
    cart("personal").forEach((item, id) => {
      const medicine = item?.kind === "medicine" || Boolean(medicineByCartKey(id));
      if (scope === "all" || medicine === includeMedicine) {
        selected.set(id, typeof item === "number" ? item : { ...item });
      }
    });
    return selected;
  };

  const cartComposition = () => {
    const personalLines = cartCommitmentLines("personal");
    const retailLines = personalLines.filter((line) => !line.isMedicine);
    const medicineLines = personalLines.filter((line) => line.isMedicine);
    const wholesaleLines = cartCommitmentLines("business");
    const retailCount = retailLines.reduce(
      (total, line) => total + (line.isHouseholdBasket ? line.details.itemCount : 1),
      0,
    );
    const medicineCount = medicineLines.length;
    const wholesaleCount = wholesaleLines.length;
    const kinds = [
      retailCount ? "Shop" : null,
      medicineCount ? "Medicine" : null,
      wholesaleCount ? "Wholesale" : null,
    ].filter(Boolean);
    const personalKinds = [
      retailCount ? "Shop" : null,
      medicineCount ? "Medicine" : null,
    ].filter(Boolean);
    return {
      retailCount,
      medicineCount,
      wholesaleCount,
      label: kinds.join(" + ") || "Cart",
      personalLabel: personalKinds.join(" + ") || "Shop",
    };
  };

  const updateCartSurfaces = () => {
    const retailStats = cartStats("personal");
    const wholesaleStats = cartStats("business");
    const stats = {
      count: retailStats.count + wholesaleStats.count,
      total: retailStats.total + wholesaleStats.total,
    };
    const pill = document.querySelector(".basket-pill");
    pill.hidden =
      stats.count === 0
      || !["catalogue", "medicine"].includes(visibleView());
    pill.classList.toggle("is-cart-notice", Boolean(state.cartNoticeName));
    pill.setAttribute(
      "aria-label",
      `Open cart · ${stats.count} ${stats.count === 1 ? "item" : "items"} · ${money(stats.total)}`,
    );
    document.querySelector("[data-basket-pill-count]").textContent = String(stats.count);
    document.querySelector("[data-basket-pill-total]").textContent = money(stats.total);
    document.querySelector("[data-basket-pill-label]").textContent =
      state.cartNoticeName ? "Added" : "Cart";
    document.querySelector("[data-basket-pill-copy]").textContent =
      state.cartNoticeName || `${stats.count} ${stats.count === 1 ? "item" : "items"}`;
  };

  const announceCartAddition = (productName) => {
    clearTimeout(cartNoticeTimer);
    state.cartNoticeName = productName;
    updateCartSurfaces();
    cartNoticeTimer = setTimeout(() => {
      state.cartNoticeName = "";
      updateCartSurfaces();
    }, 2600);
  };

  const addToCart = (id, quantity = 1, packIndex = 0) => {
    const product = products.find((item) => item.id === id);
    if (!product) return;
    const appliedQuantity = Math.max(quantity, minimumQuantity(product, packIndex));
    const existing = cart().get(id);
    const normalized = typeof existing === "number"
      ? { quantity: existing, packIndex: 0 }
      : existing;
    const nextQuantity = normalized?.packIndex === packIndex
      ? normalized.quantity + appliedQuantity
      : appliedQuantity;
    cart().set(id, { quantity: nextQuantity, packIndex });
    state.addressConfirmationKey = null;
    state.cartScope = availableCartScopes().length > 1
      ? "all"
      : state.context === "business" ? "wholesale" : "shop";
    announceCartAddition(product.title);
  };

  const addHouseholdBasketToCart = (id) => {
    const details = householdBasketDetails(id);
    if (!details || state.context !== "personal") return;
    state.carts.personal.set(householdBasketKey(id), {
      kind: "household-basket",
      basketId: id,
      members: details.members,
      quantity: 1,
      packIndex: 0,
    });
    state.addressConfirmationKey = null;
    state.cartScope = availableCartScopes().length > 1 ? "all" : "shop";
    announceCartAddition(details.title);
    renderHouseholdBasketOffer();
  };

  const changeHouseholdBasketMembers = (id, delta) => {
    const offer = householdBasketOffer(id);
    if (!offer) return;
    const nextMembers = Math.min(
      8,
      Math.max(2, (state.householdBasketMembers[id] || offer.baseMembers) + delta),
    );
    state.householdBasketMembers[id] = nextMembers;
    state.addressConfirmationKey = null;
    const cartItem = state.carts.personal.get(householdBasketKey(id));
    if (cartItem?.kind === "household-basket") {
      state.carts.personal.set(householdBasketKey(id), {
        ...cartItem,
        members: nextMembers,
      });
    }
    updateCartSurfaces();
    renderHouseholdBasketOffer();
    if (visibleView() === "basket") renderBasket();
    hapticTick();
  };

  const changeCartQuantity = (id, delta, context = state.context) => {
    const product = products.find((item) => item.id === id);
    const existing = cart(context).get(id);
    const medicineProduct = context === "personal" ? medicineByCartKey(id) : null;
    if (!existing || (!product && !medicineProduct)) return;
    state.addressConfirmationKey = null;
    if (medicineProduct && existing?.kind === "medicine") {
      const nextQuantity = (Number(existing.quantity) || 1) + delta;
      if (nextQuantity < 1) cart(context).delete(id);
      else cart(context).set(id, { ...existing, quantity: nextQuantity });
      updateCartSurfaces();
      if (visibleView() === "basket") renderBasket();
      if (visibleView() === "medicine") renderMedicine();
      hapticTick();
      return;
    }
    inBuyContext(context, () => {
      const normalized = typeof existing === "number"
        ? { quantity: existing, packIndex: 0 }
        : existing;
      const minimum = minimumQuantity(product, normalized.packIndex);
      const nextQuantity = normalized.quantity + delta;
      if (nextQuantity < minimum) cart(context).delete(id);
      else cart(context).set(id, { ...normalized, quantity: nextQuantity });
    });
    updateCartSurfaces();
    renderProducts();
    if (visibleView() === "basket") renderBasket();
    hapticTick();
  };

  const paymentChoices = () =>
    state.context === "business"
      ? [
          ["bank", "BANK", "Bank transfer", "Before dispatch"],
          ["upi", "UPI", "UPI", "When accepted"],
          ["credit", "7D", "7-day credit", "Approved"],
        ]
      : [
          ["upi", "UPI", "UPI", "Fast and secure"],
          ["card", "CARD", "Card", "Visa, Mastercard, RuPay"],
          ["cod", "CASH", "Pay on delivery", "Cash or UPI"],
        ];

  const renderPaymentOptions = (target, { compact = false } = {}) => {
    const options = paymentChoices();
    if (!options.some(([id]) => id === state.payment)) state.payment = options[0][0];
    target.innerHTML = options
      .map(
        ([id, icon, title, note]) => `
          <button class="payment-option ${compact ? "compact" : ""} ${state.payment === id ? "active" : ""}"
            type="button" role="radio" aria-checked="${state.payment === id}" data-payment="${id}">
            <span>${icon}</span><span><strong>${title}</strong><small>${note}</small></span><i class="payment-radio"></i>
          </button>`,
      )
      .join("");
  };

  const renderCartCheckout = (scope = state.cartScope) => {
    const checkout = document.querySelector("[data-cart-checkout]");
    const combinedCheckout = document.querySelector("[data-combined-cart-checkout]");
    const hasPersonal = cartStatsForLines(personalCartLines(), "personal").count > 0;
    const hasWholesale = cartScopeStats("wholesale").count > 0;
    const combined = scope === "all" && hasPersonal && hasWholesale;
    checkout.hidden = true;
    combinedCheckout.hidden = true;

    if (combined) {
      const composition = cartComposition();
      const retailCommitment = cartCommitmentSummary("personal");
      const wholesaleCommitment = cartCommitmentSummary("business");
      document.querySelector("[data-combined-personal-kind]").textContent =
        `${composition.personalLabel} order`;
      document.querySelector("#combined-cart-checkout-title").textContent = "Complete your Cart";
      document.querySelector("[data-combined-retail-address]").textContent =
        state.locations.personal.address;
      document.querySelector("[data-combined-retail-delivery]").textContent =
        retailCommitment.title;
      document.querySelector("[data-combined-wholesale-address]").textContent =
        state.locations.business.address;
      document.querySelector("[data-combined-wholesale-delivery]").textContent =
        wholesaleCommitment.title;
      combinedCheckout.hidden = false;
      return;
    }

    const context = scope === "wholesale" ? "business" : "personal";
    const lines = scope === "all" ? personalCartLines() : cartScopeLines(scope);
    const stats = scope === "all"
      ? cartStatsForLines(lines, "personal")
      : cartScopeStats(scope);
    const business = context === "business";
    const location = state.locations[context];
    const commitmentOverview = commitmentSummaryForLines(lines, context);
    checkout.hidden = stats.count === 0;
    if (stats.count === 0) return;

    document.querySelector("#cart-checkout-title").textContent =
      business ? "Complete your purchase order"
        : scope === "medicine" ? "Complete your medicine order"
          : scope === "shop" ? "Complete your Shop order" : "Complete your order";
    document.querySelector("[data-cart-address-label]").textContent =
      business ? "Deliver to business" : "Deliver to";
    document.querySelector("[data-cart-address-value]")
      .closest("[data-action='change-address']").dataset.addressContext = context;
    document.querySelector("[data-cart-address-value]").textContent = location.address;
    document.querySelector("[data-cart-address-detail]").textContent = location.detail;
    document.querySelector("[data-cart-slot-label]").textContent =
      business ? "Supplier deliveries" : "Delivery";
    document.querySelector("[data-cart-slot-value]").textContent = commitmentOverview.title;
    document.querySelector("[data-cart-slot-detail]").textContent = commitmentOverview.detail;
    document.querySelector("[data-cart-payment-kicker]").textContent =
      business ? "Approved terms" : "Secure payment";
    document.querySelector("[data-cart-payment-title]").textContent =
      business ? "Choose payment terms" : "Pay with";
    document.querySelector("[data-cart-business-consent]").hidden = !business;
    inBuyContext(context, () => {
      renderPaymentOptions(document.querySelector("[data-cart-payment-options]"), {
        compact: true,
      });
    });
  };

  const rememberCartReturnView = () => {
    state.cartReturnView = visibleView() === "medicine"
      ? "medicine"
      : state.context === "business" ? "wholesale" : "retail";
  };

  const returnFromEmptyCart = () => {
    const target = ["retail", "wholesale", "medicine"].includes(state.cartReturnView)
      ? state.cartReturnView
      : state.context === "business" ? "wholesale" : "retail";
    state.context = target === "wholesale" ? "business" : "personal";
    state.cartScope = target === "wholesale"
      ? "wholesale"
      : target === "medicine" ? "medicine" : "shop";
    setUrl({ context: target === "wholesale" ? "business" : null }, false);
    showView(target === "medicine" ? "medicine" : "catalogue", { push: false });
    renderContext();
  };

  const renderBasket = () => {
    const shopStats = cartScopeStats("shop");
    const medicineStats = cartScopeStats("medicine");
    const wholesaleStats = cartScopeStats("wholesale");
    const personalStats = cartStatsForLines(personalCartLines(), "personal");
    const composition = cartComposition();
    const allStats = cartScopeStats("all");
    if (allStats.count === 0) {
      returnFromEmptyCart();
      return;
    }
    const availableScopes = availableCartScopes();
    if (state.cartScope === "retail") state.cartScope = "shop";
    if (state.cartScope === "all" && availableScopes.length < 2) {
      state.cartScope = availableScopes[0] || (state.context === "business" ? "wholesale" : "shop");
    }
    if (state.cartScope !== "all" && !availableScopes.includes(state.cartScope)) {
      state.cartScope = availableScopes[0] || "shop";
    }
    const scope = state.cartScope;
    const combined = scope === "all";
    const business = scope === "wholesale";
    if (!combined) {
      state.context = business ? "business" : "personal";
      app.dataset.buyContext = state.context;
      renderLocation();
      setDock("basket");
      setUrl({
        cart: scope,
        cartReturn: state.cartReturnView,
        context: business ? "business" : null,
      }, false);
    }
    const stats = combined
      ? allStats
      : scope === "shop" ? shopStats
        : scope === "medicine" ? medicineStats : wholesaleStats;
    const personalLines = cartCommitmentLines("personal").map((line) => ({
      ...line,
      context: "personal",
      facts: line.isHouseholdBasket
        ? null
        : line.isMedicine
          ? {
              ordered: `${line.normalized.quantity} ${line.normalized.quantity === 1 ? "pack" : "packs"}`,
            }
        : inBuyContext("personal", () =>
            packFacts(line.product, line.normalized.packIndex, line.normalized.quantity)),
    }));
    const wholesaleLines = cartCommitmentLines("business").map((line) => ({
      ...line,
      context: "business",
      facts: inBuyContext("business", () =>
        packFacts(line.product, line.normalized.packIndex, line.normalized.quantity)),
    }));
    const shopLines = personalLines.filter((line) => !line.isMedicine);
    const medicineLines = personalLines.filter((line) => line.isMedicine);
    const basketLines = combined
      ? [...shopLines, ...medicineLines, ...wholesaleLines]
      : scope === "shop" ? shopLines
        : scope === "medicine" ? medicineLines : wholesaleLines;
    const itemCount = stats.count;

    document.querySelector("[data-basket-title]").textContent = "Cart";
    document.querySelectorAll("[data-cart-scope]").forEach((button) => {
      const buttonScope = button.dataset.cartScope;
      button.hidden =
        (buttonScope === "all" && availableScopes.length < 2) ||
        (buttonScope !== "all" && !availableScopes.includes(buttonScope));
      const active = button.dataset.cartScope === scope;
      button.classList.toggle("active", active);
      button.setAttribute("aria-selected", String(active));
      button.setAttribute("tabindex", active ? "0" : "-1");
    });
    document.querySelector("[data-cart-scope-count='all']").textContent =
      String(allStats.count);
    document.querySelector("[data-cart-scope-count='shop']").textContent =
      String(shopStats.count);
    document.querySelector("[data-cart-scope-count='wholesale']").textContent =
      String(wholesaleStats.count);
    document.querySelector("[data-cart-scope-count='medicine']").textContent =
      String(medicineStats.count);
    document.querySelector("[data-cart-scope-total='all']").textContent = money(allStats.total);
    document.querySelector("[data-cart-scope-total='shop']").textContent = money(shopStats.total);
    document.querySelector("[data-cart-scope-total='wholesale']").textContent = money(wholesaleStats.total);
    document.querySelector("[data-cart-scope-total='medicine']").textContent = money(medicineStats.total);

    const scopeLabel = combined
      ? composition.label
      : business ? "Wholesale order" : scope === "medicine" ? "Medicine order" : "Shop order";
    const scopeAccount = combined ? "One Cart · separated purchase types" : business
      ? state.locations.business.address
      : state.locations.personal.address;
    document.querySelector("[data-cart-toolbar-summary]").textContent = combined
      ? `${itemCount} ${itemCount === 1 ? "product" : "products"} · ${composition.label} · ${money(stats.total)}`
      : `${itemCount} ${itemCount === 1 ? "product" : "products"} · ${business ? "Wholesale" : scope === "medicine" ? "Medicine" : "Shop"} · ${money(stats.total)}`;
    document.querySelector("[data-basket-context]").innerHTML = `
      <span class="cart-context-icon" aria-hidden="true">
        <svg viewBox="0 0 24 24"><path d="M3 4h2l2 11h10l3-8H7M9 20h.01M17 20h.01" /></svg>
      </span>
      <span>
        <small>${scopeAccount}</small>
        <strong>${scopeLabel}</strong>
        <em>${itemCount} ${itemCount === 1 ? "product" : "products"} · ${money(stats.total)}</em>
      </span>`;

    const shopCommitment = commitmentSummaryForLines(shopCartLines(), "personal");
    const medicineCommitmentSummary = commitmentSummaryForLines(medicineCartLines(), "personal");
    const wholesaleCommitment = cartCommitmentSummary("business");
    const commitmentSummary = document.querySelector("[data-basket-commitment-summary]");
    commitmentSummary.hidden = true;
    commitmentSummary.innerHTML = "";

    const renderBasketLine = ({
      id,
      product,
      normalized,
      offer,
      facts,
      isHouseholdBasket,
      isMedicine,
      details,
      context,
    }) => {
      if (isHouseholdBasket) {
        return `
          <article class="basket-item household-basket-cart-item">
            <span class="basket-item-art household-basket-cart-art" aria-hidden="true">
              <span>${art.atta}</span><span>${art.rice}</span><span>${art.oil}</span><span>${art.soap}</span>
            </span>
            <span class="basket-item-copy">
              <strong>${details.title}</strong>
              <span>${details.seller} · ${details.itemCount} products · ${details.packCount} packs · ${details.duration}</span>
              <em>${details.commitment.route}</em>
              <small>${details.commitment.delivery} · ${details.commitment.confirmed}</small>
            </span>
            <span class="basket-item-end">
              <strong>${money(details.price)}</strong>
              <small>${details.members} members · Save ${money(details.saving)}</small>
              <div class="basket-stepper" role="group" aria-label="Household members">
                <button type="button" data-household-member-decrease="${details.id}"
                  aria-label="Remove one household member" ${details.members <= 2 ? "disabled" : ""}>−</button>
                <b>${details.members}</b>
                <button type="button" data-household-member-increase="${details.id}"
                  aria-label="Add one household member" ${details.members >= 8 ? "disabled" : ""}>+</button>
              </div>
            </span>
            <button class="basket-remove" type="button" data-remove="${id}"
              data-cart-context="personal" aria-label="Remove ${details.title}">
              <svg viewBox="0 0 24 24" aria-hidden="true"><path d="M5 7h14M9 7V4h6v3M8 7l1 13h6l1-13M10 11v5M14 11v5" /></svg>
            </button>
            <details class="cart-household-products">
              <summary>${details.itemCount} products in this basket</summary>
              <div>
                ${details.itemLines
                  .map(
                    ({ product: basketProduct, quantity, pack }) => `
                      <span><b>${basketProduct.title}</b><small>${quantity} × ${pack}</small></span>`,
                  )
                  .join("")}
              </div>
            </details>
          </article>`;
      }
      if (isMedicine) {
        const fixedPrescriptionQuote =
          id === medicineCartKey(prescriptionQuoteProduct.id);
        return `
          <article class="basket-item medicine-basket-item">
            <span class="basket-item-art medicine-basket-art" aria-hidden="true">${product.medicineGlyph || "+"}</span>
            <span class="basket-item-copy">
              <strong>${product.title}</strong>
              <span>${offer.variant} · ${offer.pack} · ${offer.unit}</span>
              <em>${offer.commitment.route}</em>
              <small>${offer.commitment.delivery} · ${offer.commitment.confirmed}</small>
            </span>
            <span class="basket-item-end">
              <strong>${money(offer.price * normalized.quantity)}</strong>
              <small>${fixedPrescriptionQuote ? "1 reviewed quote" : facts.ordered}</small>
              ${fixedPrescriptionQuote
                ? `<span class="prescription-quantity-lock">Pharmacist-approved</span>`
                : `<div class="basket-stepper" role="group" aria-label="${product.title} quantity">
                    <button type="button" data-card-decrease="${id}" data-cart-context="${context}"
                      aria-label="Decrease ${product.title} quantity">−</button>
                    <b>${normalized.quantity}</b>
                    <button type="button" data-card-increase="${id}" data-cart-context="${context}"
                      aria-label="Increase ${product.title} quantity">+</button>
                  </div>`}
            </span>
            <button class="basket-remove" type="button" data-remove="${id}"
              data-cart-context="${context}" aria-label="Remove ${product.title}">
              <svg viewBox="0 0 24 24" aria-hidden="true"><path d="M5 7h14M9 7V4h6v3M8 7l1 13h6l1-13M10 11v5M14 11v5" /></svg>
            </button>
          </article>`;
      }
      return `
        <article class="basket-item">
          <span class="basket-item-art">${art[product.visual]}</span>
          <span class="basket-item-copy">
            <strong>${product.title}</strong>
            <span>${offer.variant} · ${offer.pack} · ${offer.unit}</span>
            <em>${offer.commitment.route}</em>
            <small>${offer.commitment.delivery} · ${offer.commitment.confirmed}</small>
          </span>
          <span class="basket-item-end">
            <strong>${money(offer.price * normalized.quantity)}</strong>
            <small>${facts.ordered}</small>
            <div class="basket-stepper" role="group" aria-label="${product.title} quantity">
              <button type="button" data-card-decrease="${id}" data-cart-context="${context}"
                aria-label="Decrease ${product.title} quantity">−</button>
              <b>${normalized.quantity}</b>
              <button type="button" data-card-increase="${id}" data-cart-context="${context}"
                aria-label="Increase ${product.title} quantity">+</button>
            </div>
          </span>
          <button class="basket-remove" type="button" data-remove="${id}"
            data-cart-context="${context}" aria-label="Remove ${product.title}">
            <svg viewBox="0 0 24 24" aria-hidden="true"><path d="M5 7h14M9 7V4h6v3M8 7l1 13h6l1-13M10 11v5M14 11v5" /></svg>
          </button>
        </article>`;
    };

    const basketItems = document.querySelector("[data-basket-items]");
    const renderWholesaleGroups = (lines) => {
      const supplierGroups = new Map();
      lines.forEach((line) => {
        if (!supplierGroups.has(line.offer.seller)) supplierGroups.set(line.offer.seller, []);
        supplierGroups.get(line.offer.seller).push(line);
      });
      return [...supplierGroups.entries()]
        .map(([, lines], index) => {
          const { offer } = lines[0];
          return `
            <section class="supplier-order-group" aria-labelledby="supplier-group-${index}">
              <header>
                <span>
                  <small>Supplier ${index + 1}</small>
                  <strong id="supplier-group-${index}">${offer.seller}</strong>
                  <em>${offer.commitment.origin.city}, ${offer.commitment.origin.state} · ${offer.commitment.confirmed}</em>
                </span>
                <b>${offer.commitment.dispatch}<small>Dispatch</small></b>
              </header>
              <div>${lines.map(renderBasketLine).join("")}</div>
            </section>`;
        })
        .join("");
    };

    const renderCartGroup = (kind, lines, groupStats) => {
      const wholesale = kind === "wholesale";
      const medicine = kind === "medicine";
      const context = wholesale ? "business" : "personal";
      const commitment = wholesale
        ? wholesaleCommitment
        : medicine ? medicineCommitmentSummary : shopCommitment;
      const groupTitle = wholesale
        ? "Wholesale order"
        : medicine ? "Medicine order" : "Shop order";
      const groupKicker = wholesale
        ? "Verified workspace"
        : medicine ? "Licensed pharmacy delivery" : "Customer delivery";
      const displayTotal = combined ? groupStats.subtotal : groupStats.total;
      return `
        <section class="cart-order-section ${kind}"
          aria-labelledby="cart-order-${kind}">
          <header>
            <span class="cart-order-badge" aria-hidden="true">${wholesale ? "W" : medicine ? "M" : "S"}</span>
            <span>
              <small>${groupKicker}</small>
              <strong id="cart-order-${kind}">${groupTitle}</strong>
              <em>${commitment.title}</em>
            </span>
            <b>${money(displayTotal)}<small>${combined ? "Products" : wholesale ? "Landed" : "Delivered"}</small></b>
          </header>
          <div class="cart-order-lines">
            ${wholesale ? renderWholesaleGroups(lines) : lines.map(renderBasketLine).join("")}
          </div>
        </section>`;
    };

    if (combined) {
      basketItems.innerHTML = [
        shopLines.length ? renderCartGroup("shop", shopLines, shopStats) : "",
        medicineLines.length ? renderCartGroup("medicine", medicineLines, medicineStats) : "",
        wholesaleLines.length ? renderCartGroup("wholesale", wholesaleLines, wholesaleStats) : "",
      ].join("");
    } else if (business) {
      basketItems.innerHTML = renderCartGroup("wholesale", wholesaleLines, wholesaleStats);
    } else if (scope === "medicine") {
      basketItems.innerHTML = renderCartGroup("medicine", medicineLines, medicineStats);
    } else {
      basketItems.innerHTML = renderCartGroup("shop", shopLines, shopStats);
    }

    basketItems.hidden = basketLines.length === 0;
    document.querySelector("[data-basket-summary]").hidden = basketLines.length === 0;
    document.querySelector(".basket-continue").hidden = basketLines.length === 0;
    document.querySelector(".basket-add-products").hidden = basketLines.length === 0;
    document.querySelector("[data-basket-subtotal]").textContent = money(stats.subtotal);
    document.querySelector("[data-basket-delivery]").textContent = stats.delivery ? money(stats.delivery) : "Included";
    document.querySelector("[data-basket-total]").textContent = money(stats.total);
    document.querySelector("[data-checkout-total]").textContent = money(stats.total);
    document.querySelector("[data-delivery-label]").textContent =
      combined ? "Delivery + freight" : business ? "Freight" : "Delivery";
    document.querySelector("[data-total-label]").textContent =
      combined ? "Combined total" : business ? "Landed total" : "Total";
    document.querySelector("[data-total-note]").textContent =
      combined
        ? `${composition.label} · each order is confirmed separately before payment`
        : business ? "Tax and freight shown for every item"
          : scope === "medicine" ? "Prescription and pharmacy checks remain attached" : "Includes all charges shown above";
    document.querySelector("[data-checkout-label]").textContent =
      combined ? "Place selected orders" : business ? "Place purchase order" : "Pay securely";
    document.querySelector(".basket-add-products").textContent =
      combined ? "Add more products"
        : business ? "Add wholesale products"
          : scope === "medicine" ? "Add medicines" : "Add Shop products";
    renderCartCheckout(scope);
  };

  const renderCheckout = () => {
    const stats = cartStats();
    const business = state.context === "business";
    const location = state.locations[state.context];
    const commitmentOverview = cartCommitmentSummary();
    document.querySelector("[data-checkout-title]").textContent = business ? "Review purchase order" : "Review order";
    document.querySelector("[data-address-label]").textContent = business ? "Deliver to business" : "Deliver to";
    document.querySelector("[data-address-value]")
      .closest("[data-action='change-address']").dataset.addressContext = state.context;
    document.querySelector("[data-address-value]").textContent = location.address;
    document.querySelector("[data-address-detail]").textContent = location.detail;
    document.querySelector("[data-slot-label]").textContent = business ? "Supplier deliveries" : "Delivery";
    document.querySelector("[data-slot-value]").textContent = commitmentOverview.title;
    document.querySelector("[data-slot-detail]").textContent = commitmentOverview.detail;
    document.querySelector("[data-payment-kicker]").textContent = business ? "Approved terms" : "Secure payment";
    document.querySelector("[data-payment-title]").textContent = business ? "Choose payment terms" : "Choose payment method";
    document.querySelector("[data-review-total-label]").textContent = business ? "Purchase order total" : "Amount to pay";
    document.querySelector("[data-review-total]").textContent = money(stats.total);
    document.querySelector("[data-review-note]").textContent = business
      ? "Pack, MOQ, tax, freight, stock and terms will be checked before the purchase order is placed."
      : "Price and stock will be checked once more before payment.";
    document.querySelector("[data-business-consent]").hidden = !business;
    document.querySelector("[data-confirm-label]").textContent = business ? "Place purchase order" : "Pay securely";
    document.querySelector("[data-confirm-total]").textContent = money(stats.total);

    renderPaymentOptions(document.querySelector("[data-payment-options]"));
  };

  const orderRecords = () => [
    {
      id: "retail-active",
      context: "personal",
      kind: "shop",
      status: "active",
      number: "MS-240782",
      title: "Shop order",
      summary: "13 products · Home · Sardarpura",
      state: "Preparing your order",
      stateNote: "Every local partner has confirmed stock",
      date: deliveryCommitment(products.find((product) => product.id === "atta"), products.find((product) => product.id === "atta").personal, 0, "personal").delivery,
      amount: cartStats("personal").total || 4839,
      progress: 54,
      destination: state.locations.personal.address,
      partner: "Sardarpura Supermart + nearby partners",
      partnerType: "Local retailers",
    },
    {
      id: "wholesale-active",
      context: "business",
      kind: "wholesale",
      status: "active",
      number: "PO-240783",
      title: "Wholesale order",
      summary: "1 trade product · Shree Balaji Retail",
      state: "Supplier confirmation",
      stateNote: "Dispatch follows confirmed stock",
      date: deliveryCommitment(products.find((product) => product.id === "atta"), products.find((product) => product.id === "atta").business, 0, "business").delivery,
      amount: cartStats("business").total || 4200,
      progress: 34,
      destination: state.locations.business.address,
      partner: "Marwar Foods Distribution",
      partnerType: "Verified distributor",
    },
    {
      id: "medicine-active",
      context: "personal",
      kind: "medicine",
      status: "active",
      number: "RX-240784",
      title: "Medicine order",
      summary: "2 products · Home · Sardarpura",
      state: "Pharmacy packing",
      stateNote: "Prescription and stock have been checked",
      date: medicineCommitment(medicineProducts[0]).delivery,
      amount: 684,
      progress: 68,
      destination: state.locations.personal.address,
      partner: "Sardarpura Health Pharmacy",
      partnerType: "Licensed pharmacy",
    },
    {
      id: "retail-delivered",
      context: "personal",
      kind: "shop",
      status: "delivered",
      number: "MS-220764",
      title: "Weekly essentials",
      summary: "3 products · Home · Sardarpura",
      state: "Delivered",
      stateNote: "Delivered to Dharmendra",
      date: "Thu, 23 Jul · 7:18 pm",
      amount: 1269,
      progress: 100,
      destination: state.locations.personal.address,
      partner: "Ghar Bazaar Sardarpura",
      partnerType: "Local shop",
    },
    {
      id: "wholesale-delivered",
      context: "business",
      kind: "wholesale",
      status: "delivered",
      number: "PO-210759",
      title: "Store restock",
      summary: "2 trade products · Shree Balaji Retail",
      state: "Delivered",
      stateNote: "All supplier quantities received",
      date: "Sat, 18 Jul · 4:42 pm",
      amount: 8460,
      progress: 100,
      destination: state.locations.business.address,
      partner: "Thar Grains Wholesale",
      partnerType: "Verified wholesaler",
    },
    {
      id: "medicine-delivered",
      context: "personal",
      kind: "medicine",
      status: "delivered",
      number: "RX-200751",
      title: "Medicines and health",
      summary: `2 products · ${state.locations.personal.address}`,
      state: "Delivered",
      stateNote: "Sealed packs received",
      date: "Mon, 13 Jul · 8:06 pm",
      amount: 134,
      progress: 100,
      destination: state.locations.personal.address,
      partner: "Sardarpura Health Pharmacy",
      partnerType: "Licensed pharmacy",
    },
  ];

  const findOrder = (id = state.activeOrderId) =>
    orderRecords().find((order) => order.id === id) || orderRecords()[0];

  const orderKindMark = (order) =>
    order.kind === "medicine" ? "M" : order.kind === "wholesale" ? "W" : "S";

  const renderLiveOrderStatus = (view = visibleView()) => {
    if (!liveOrderStatus) return;
    const visible = ["catalogue", "product", "medicine"].includes(view);
    liveOrderStatus.hidden = !visible;
    if (!visible) return;
    const records = orderRecords().filter((order) => order.status === "active");
    const preferredId = view === "medicine"
      ? "medicine-active"
      : state.context === "business" ? "wholesale-active" : "retail-active";
    const order = records.find((item) => item.id === preferredId) || records[0];
    if (!order) {
      liveOrderStatus.hidden = true;
      return;
    }
    state.liveOrderId = order.id;
    liveOrderStatus.querySelector("[data-live-order-kicker]").textContent =
      `${records.length} active ${records.length === 1 ? "order" : "orders"}`;
    liveOrderStatus.querySelector("[data-live-order-title]").textContent =
      `${order.state} · ${order.date}`;
    liveOrderStatus.querySelector("[data-live-order-partner]").textContent = order.partner;
    liveOrderStatus.querySelector("[data-live-order-partner-type]").textContent = order.partnerType;
    liveOrderStatus.setAttribute(
      "aria-label",
      `Track ${order.title}. ${order.state}. ${order.date}. Fulfilled by ${order.partner}, ${order.partnerType}.`,
    );
  };

  const openOrder = (id) => {
    const order = findOrder(id);
    state.activeOrderId = order.id;
    state.context = order.context;
    setUrl({
      context: order.context === "business" ? "business" : null,
      order: order.id,
      received: order.status === "delivered" ? "1" : null,
    }, false);
    renderContext();
    showView("tracking");
  };

  const renderOrders = () => {
    const emptyState = query().get("ordersState") === "empty";
    const records = emptyState
      ? []
      : orderRecords().filter((order) => order.status === state.ordersTab);
    const allRecords = emptyState ? [] : orderRecords();
    document.querySelector("[data-orders-active-count]").textContent =
      String(allRecords.filter((order) => order.status === "active").length);
    document.querySelector("[data-orders-delivered-count]").textContent =
      String(allRecords.filter((order) => order.status === "delivered").length);
    document.querySelector("[data-orders-next-date]").textContent =
      allRecords.find((order) => order.status === "active")?.date.split("·")[0].trim() || "—";
    document.querySelectorAll("[data-orders-tab]").forEach((button) => {
      const active = button.dataset.ordersTab === state.ordersTab;
      button.classList.toggle("active", active);
      button.setAttribute("aria-selected", String(active));
      button.setAttribute("tabindex", active ? "0" : "-1");
    });
    ordersEmpty.hidden = records.length > 0;
    ordersList.hidden = records.length === 0;
    ordersList.innerHTML = records.map((order) => `
      <article class="order-card ${order.kind}">
        <header>
          <span class="order-kind" aria-hidden="true">${orderKindMark(order)}</span>
          <span>
            <small>${order.number}</small>
            <strong>${order.title}</strong>
            <em>${order.summary}</em>
          </span>
          <b>${money(order.amount)}</b>
        </header>
        <div class="order-status-line">
          <span><small>${order.state}</small><strong>${order.date}</strong></span>
          <b>${order.status === "delivered" ? "Delivered" : `${order.progress}%`}</b>
        </div>
        <div class="order-progress" aria-label="${order.state}">
          <i style="--order-progress:${order.progress}%"></i>
        </div>
        <p class="order-partner"><strong>${order.partner}</strong><span>${order.partnerType}</span></p>
        <p>${order.stateNote}</p>
        <div class="order-card-actions">
          <button type="button" data-open-order="${order.id}">
            ${order.status === "delivered" ? "View order" : "Track order"}
          </button>
          ${order.status === "delivered"
            ? `<button type="button" data-reorder-order="${order.id}">Reorder</button>`
            : ""}
        </div>
      </article>`).join("");
  };

  const renderConfirmation = () => {
    const scope = state.lastConfirmationScope === "retail"
      ? "shop"
      : state.lastConfirmationScope;
    const combined = scope === "all";
    const business = scope === "wholesale";
    const medicine = scope === "medicine";
    const activeKinds = combined ? availableCartScopes() : [scope];
    const commitmentOverview = commitmentSummaryForLines(
      scope === "all" ? personalCartLines() : cartScopeLines(scope),
      business ? "business" : "personal",
    );
    const commitmentNotes = activeKinds.map((kind) => {
      const context = kind === "wholesale" ? "business" : "personal";
      const summary = commitmentSummaryForLines(cartScopeLines(kind), context);
      return `${kind === "shop" ? "Shop" : kind === "medicine" ? "Medicine" : "Wholesale"}: ${summary.title}`;
    });
    const confirmationRecords = activeKinds.map((kind) => {
      const context = kind === "wholesale" ? "business" : "personal";
      const order = findOrder(kind === "shop"
        ? "retail-active"
        : kind === "medicine" ? "medicine-active" : "wholesale-active");
      const summary = commitmentSummaryForLines(cartScopeLines(kind), context);
      const scopeStats = cartScopeStats(kind);
      return {
        ...order,
        date: summary.title,
        amount: scopeStats.total || order.amount,
      };
    });
    document.querySelector("[data-confirmation-toolbar]").textContent =
      combined ? "Orders placed" : business ? "Purchase order placed" : "Order placed";
    document.querySelector("[data-confirmation-kicker]").textContent =
      combined ? "Thank you" : business ? "Purchase order received" : "Thank you";
    document.querySelector("[data-confirmation-title]").textContent =
      combined ? "Your orders are confirmed" : business ? "Purchase order placed"
        : medicine ? "Medicine order confirmed" : "Order confirmed";
    document.querySelector("[data-confirmation-note]").textContent = combined
      ? `${commitmentNotes.join(". ")}.`
      : business
      ? `Supplier-confirmed deliveries: ${commitmentOverview.title}. Follow each dispatch from your purchase order.`
      : medicine
        ? `Your pharmacy-confirmed medicines are scheduled for ${commitmentOverview.title}.`
        : `Your products are scheduled for ${commitmentOverview.title}.`;
    document.querySelector("[data-confirmation-number-label]").textContent =
      combined ? "Orders" : business ? "Purchase order" : "Order";
    document.querySelector("[data-confirmation-number]").textContent =
      confirmationRecords.map((order) => order.number).join(" · ");
    document.querySelector("[data-confirmation-orders]").innerHTML =
      confirmationRecords.map((order) => `
        <button class="confirmation-order-card ${order.kind}"
          type="button" data-open-order="${order.id}">
          <span class="order-kind" aria-hidden="true">${orderKindMark(order)}</span>
          <span>
            <small>${order.number}</small>
            <strong>${order.title}</strong>
            <em>${order.date}</em>
          </span>
          <span><strong>${money(order.amount)}</strong><small>Track</small></span>
        </button>`).join("");
    document.querySelector("[data-confirmation-progress]").hidden = combined;
    document.querySelector("[data-confirmation-progress-title]").textContent =
      combined ? "Orders in progress" : business ? "Supplier confirmation"
        : medicine ? "Pharmacy packing" : "Preparing your order";
    document.querySelector("[data-confirmation-progress-time]").textContent = "Now";
    document.querySelector("[data-confirmation-step-one]").textContent =
      combined ? "Orders placed" : business ? "Purchase order placed" : "Order confirmed";
    document.querySelector("[data-confirmation-step-one-note]").textContent =
      combined ? "Each purchase type is recorded separately" : business ? "Terms and quantities recorded"
        : medicine ? "Prescription, payment and stock checked" : "Payment and stock checked";
    document.querySelector("[data-confirmation-step-two]").textContent =
      combined ? "Orders in preparation" : business ? "Supplier confirmation"
        : medicine ? "Pharmacy packing" : "Preparing your order";
    document.querySelector("[data-confirmation-step-two-note]").textContent =
      combined ? "Each fulfilment partner is preparing its products" : business ? "Suppliers are confirming stock"
        : medicine ? "The licensed pharmacy is packing sealed products" : "Seller is packing your items";
    document.querySelector("[data-confirmation-step-three]").textContent =
      combined ? "Dispatch and delivery" : business ? "Dispatch" : "Out for delivery";
    document.querySelector("[data-confirmation-step-three-note]").textContent =
      combined ? "Tracking starts for each order after pickup" : business ? "Tracking starts after pickup" : "Live tracking starts after pickup";
  };

  const renderTracking = () => {
    const requestedOrder = query().get("order");
    if (orderRecords().some((order) => order.id === requestedOrder)) {
      state.activeOrderId = requestedOrder;
    }
    const order = findOrder();
    state.context = order.context;
    const business = order.context === "business";
    const medicine = order.kind === "medicine";
    const received = order.status === "delivered" || query().get("received") === "1";
    const commitmentOverview = cartCommitmentSummary();
    document.querySelector("[data-tracking-kicker]").textContent = received
      ? "Delivered"
      : medicine ? "Pharmacy preparing" : business ? "Supplier confirmation" : "Preparing your order";
    document.querySelector("[data-tracking-title]").textContent = received
      ? business ? "Purchase order delivered" : medicine ? "Medicine delivered" : "Order delivered"
      : business ? "Purchase order in progress" : medicine ? "Medicine order is on schedule" : "Order is on schedule";
    document.querySelector("[data-tracking-note]").textContent = received
      ? business
        ? "All supplier deliveries were received. Reorder the same quantities or change them before paying."
        : medicine
          ? "Delivered successfully. Your medicine details and prescription remain available for a future refill."
          : "Delivered successfully. Reorder the same products or change quantities before paying."
      : business
        ? `${order.date} · each supplier's dispatch stays visible here.`
        : medicine
          ? `${order.date} · pharmacy and delivery updates stay visible here.`
          : `${order.date} · delivery updates stay visible here.`;
    document.querySelector("[data-tracking-number]").textContent = order.number;
    document.querySelector("[data-tracking-step-one]").textContent =
      business ? "Purchase order placed" : medicine ? "Prescription checked" : "Order confirmed";
    document.querySelector("[data-tracking-step-one-note]").textContent =
      business ? "Terms and quantities recorded" : medicine ? "Medicine and quantity verified" : "Payment and stock checked";
    document.querySelector("[data-tracking-step-two]").textContent =
      business ? "Supplier confirmation" : medicine ? "Pharmacy preparing" : "Preparing your order";
    document.querySelector("[data-tracking-step-two-note]").textContent =
      business ? "One supplier has confirmed stock" : medicine ? "Sealed medicines are being packed" : "Seller is packing your items";
    document.querySelector("[data-tracking-step-three]").textContent = business ? "Dispatch" : "Out for delivery";
    document.querySelector("[data-tracking-step-three-note]").textContent = business ? "Shipment tracking starts after pickup" : "Live tracking starts after pickup";
    document.querySelector("[data-tracking-update-title]").textContent = received
      ? business ? "All supplier deliveries received" : medicine ? "Medicine delivered to Dharmendra" : "Delivered to Dharmendra"
      : business ? "1 of 2 suppliers confirmed" : medicine ? "Pharmacist completed the review" : "Seller confirmed your order";
    document.querySelector("[data-tracking-update-note]").textContent = received
      ? business
        ? "The received quantities match the purchase order."
        : "Delivered to Home · Sardarpura."
      : business
        ? "Marwar Foods Distribution confirmed the ordered quantity. The second supplier is due to respond by 10:30 am."
        : medicine
          ? "Sardarpura Health Pharmacy confirmed the medicine, quantity and delivery."
          : "All items are available and preparation has started.";
    document.querySelector("[data-tracking-date-label]").textContent =
      received ? "Delivered" : business ? "Expected supply" : "Expected delivery";
    document.querySelector("[data-tracking-date]").textContent = order.date;
    document.querySelector("[data-tracking-destination]").textContent = order.destination;
    document.querySelector("[data-tracking-total-label]").textContent =
      business ? "Purchase order total" : "Total paid";
    document.querySelector("[data-tracking-total]").textContent = money(order.amount);
    document.querySelector("[data-tracking-partner]").textContent = order.partner;
    document.querySelector("[data-tracking-partner-type]").textContent = order.partnerType;

    const timeline = [...document.querySelectorAll(".tracking-timeline li")];
    timeline.forEach((item, index) => {
      item.classList.toggle("complete", received || index === 0);
      item.classList.toggle("active", !received && index === 1);
      const marker = item.querySelector(":scope > b");
      if (marker) marker.textContent = received || index === 0 ? "✓" : index === 1 ? "Now" : "";
    });
    const primary = document.querySelector("[data-tracking-primary]");
    const secondary = document.querySelector("[data-tracking-secondary]");
    primary.dataset.action = received ? "reorder" : "orders";
    document.querySelector("[data-tracking-primary-label]").textContent =
      received
        ? business ? "Reorder these supplies" : medicine ? "Refill these medicines" : "Reorder these items"
        : "View all orders";
    secondary.hidden = true;
  };

  const filterResultCount = (surface) =>
    surface === "medicine"
      ? filteredMedicineProducts().length
      : filteredCatalogueProducts().length;

  const filterLensHtml = (surface) => {
    const profile = filterProfiles[surface];
    const filters = state.filters[surface];
    const count = filterResultCount(surface);
    return `
      <div class="mool-filter-lens" data-filter-lens data-filter-surface="${surface}">
        <div class="filter-lens-status">
          <span class="filter-lens-mark" aria-hidden="true">
            <i></i><i></i><i></i>
          </span>
          <span>
            <small>${profile.kicker} filter</small>
            <strong data-filter-selection-summary>${filterSummary(surface, { includeDefaults: true })}</strong>
          </span>
          <button type="button" data-filter-reset="${surface}">Reset</button>
        </div>
        <div class="filter-lens-groups">
          ${profile.groups.map((group) => `
            <section class="filter-lens-group" data-filter-group-section="${group.id}">
              <header>
                <span aria-hidden="true">${group.glyph}</span>
                <strong>${group.label}</strong>
              </header>
              <div class="filter-lens-options" role="radiogroup" aria-label="${group.label}">
                ${group.choices.map((choice) => `
                  <button class="filter-lens-option ${filters[group.id] === choice.value ? "active" : ""}"
                    type="button" role="radio"
                    aria-checked="${filters[group.id] === choice.value}"
                    data-filter-group="${group.id}" data-filter-value="${choice.value}">
                    <span aria-hidden="true"></span>
                    <b>${choice.label}</b>
                    <small>${choice.note}</small>
                  </button>`).join("")}
              </div>
            </section>`).join("")}
        </div>
        <button class="filter-lens-apply" type="button" data-sheet-action="apply-filter">
          <span>Show results</span>
          <strong data-filter-result-count>${count} ${profile.resultLabel}</strong>
        </button>
      </div>`;
  };

  const openSheet = (type) => {
    clearTimeout(sheetCloseTimer);
    sheet.classList.remove("is-dragging", "is-settling", "is-dismissing");
    sheet.style.removeProperty("--sheet-drag-y");
    sheetKicker.textContent = "Choose";
    sheetTitle.textContent = "Options";
    sheetContent.dataset.sheetType = type;
    let html = "";

    if (type === "filters") {
      const surface = state.filterSurface === "medicine" ? "medicine" : state.context;
      state.filterSurface = surface;
      const profile = filterProfiles[surface];
      sheetKicker.textContent = profile.kicker;
      sheetTitle.textContent = profile.title;
      html = filterLensHtml(surface);
    }

    if (type === "categories") {
      const regularCategories = availableCategories().filter((item) => item.id !== "all" && !item.view);
      const medicineCategory = availableCategories().find((item) => item.view === "medicine");
      const contextLabel = state.context === "business" ? "Wholesale" : "Retail";
      sheetKicker.textContent = contextLabel;
      sheetTitle.textContent = "All categories";
      html = `
        <div class="all-categories-overview">
          <span>
            <strong>${products.length} products across ${regularCategories.length} categories</strong>
            <small>${state.context === "business"
              ? "Case packs, MOQ and landed prices for business buying"
              : "Single and small packs with delivered prices"}</small>
          </span>
          <b>${contextLabel}</b>
        </div>
        <div class="all-categories-actions">
          <button class="all-categories-featured ${discovery().category === "all" ? "active" : ""}" type="button"
            data-sheet-category="all">
            <span aria-hidden="true">✦</span>
            <b>${state.context === "business" ? "All wholesale products" : "All retail products"}<small>${products.length} products</small></b>
          </button>
          <button class="all-categories-featured" type="button" data-sheet-view="${medicineCategory.view}">
            <span aria-hidden="true">${medicineCategory.glyph}</span>
            <b>${medicineCategory.label}<small>Search and prescriptions</small></b>
          </button>
        </div>
        <div class="all-category-grid" role="group" aria-label="${contextLabel} categories">
          ${regularCategories.map((item) => {
            const count = products.filter((product) =>
              (state.context === "business" ? product.businessCategory : product.category) === item.id
            ).length;
            return `
              <button class="all-category-card ${discovery().category === item.id ? "active" : ""}" type="button"
                data-sheet-category="${item.id}">
                <span aria-hidden="true">${item.glyph}</span>
                <strong>${item.label}</strong>
                <small>${count} ${count === 1 ? "product" : "products"}</small>
              </button>`;
          }).join("")}
        </div>`;
    }

    if (type === "compare") {
      const baseOffer = state.currentProduct[state.context];
      const selectedPack = baseOffer.packs[state.selectedPack] || baseOffer.packs[0];
      const chosenSellerIndex = state.sellerChoices[state.context].get(state.currentProduct.id);
      const defaultSellerIndex = baseOffer.sellers.findIndex(
        ([, seller]) => seller === baseOffer.seller,
      );
      const activeSellerIndex = Number.isInteger(chosenSellerIndex)
        ? chosenSellerIndex
        : Math.max(0, defaultSellerIndex);
      sheetKicker.textContent = `${state.currentProduct.title} · ${selectedPack[0]}`;
      sheetTitle.textContent = state.context === "business" ? "Compare landed offers" : "Compare sellers";
      html = baseOffer.sellers
        .map(([avatar, seller, note, price, reason], index) => {
          const sellerNote = note.split(" · ");
          const commitment = deliveryCommitment(
            state.currentProduct,
            {
              ...baseOffer,
              seller,
              sellerType: sellerNote[0],
            },
            state.selectedPack,
          );
          return `
            <button class="seller-option ${index === activeSellerIndex ? "active" : ""}" type="button"
              aria-pressed="${index === activeSellerIndex}" data-seller-index="${index}">
              <span>${avatar}</span><span><strong>${seller}</strong><small>${sellerNote[0]}</small><em>${commitment.route} · ${commitment.delivery}</em></span>
              <span><strong>${money(sellerPackPrice(baseOffer, baseOffer.sellers[index], state.selectedPack))}</strong><small>${reason}</small></span>
            </button>`;
        })
        .join("");
    }

    if (type === "location") {
      const context = state.addressContext;
      const addresses = state.addressBook[context];
      const activeId = state.selectedAddressIds[context];
      sheetKicker.textContent = context === "business" ? "Business delivery" : "Delivery";
      sheetTitle.textContent = "Choose address";
      html = `
        <div class="address-list" role="radiogroup" aria-label="Saved addresses">
          ${addresses.map((address) => `
            <div class="address-option-row ${address.id === activeId ? "active" : ""}">
              <button class="address-option" type="button" role="radio"
                aria-checked="${address.id === activeId}"
                data-sheet-action="select-address" data-address-id="${escapeHtml(address.id)}"
                data-address-context="${context}">
                <span class="address-mark" aria-hidden="true">${escapeHtml(address.label.slice(0, 1).toUpperCase())}</span>
                <span>
                  <small>${escapeHtml(address.label)}</small>
                  <strong>${escapeHtml(address.recipient)}</strong>
                  <em>${escapeHtml([
                    address.detail,
                    address.phone,
                  ].filter(Boolean).join(" · "))}</em>
                </span>
                <b>${address.id === activeId ? "Selected" : "Use"}</b>
              </button>
              <button class="address-edit" type="button" aria-label="Edit ${escapeHtml(address.label)} address"
                data-sheet-action="edit-address" data-address-id="${escapeHtml(address.id)}"
                data-address-context="${context}">Edit</button>
            </div>`).join("")}
        </div>
        <div class="address-actions">
          <button type="button" data-sheet-action="use-current-address">
            <span aria-hidden="true">◎</span><b>Current location</b>
          </button>
          <button type="button" data-sheet-action="new-address">
            <span aria-hidden="true">＋</span><b>Add address</b>
          </button>
          <button type="button" data-sheet-action="request-address">
            <span aria-hidden="true">↗</span><b>Request address</b>
          </button>
        </div>`;
    }

    if (type === "address-form") {
      const context = state.addressContext;
      const editing = state.editingAddressId
        ? state.addressBook[context].find((address) => address.id === state.editingAddressId)
        : null;
      const draft = state.addressDraft || editing || {};
      const draftLabel = normalizeAddressTypeLabel(
        editing?.label || draft.label || state.addressDraftLabel || "Other place",
      );
      const draftPin = draft.pin || draft.area?.match(/\d{6}/)?.[0] || "";
      const draftArea = draft.area?.replace(/\s*·\s*\d{6}$/, "") || "";
      sheetKicker.textContent = editing ? "Delivery address" : "New delivery address";
      sheetTitle.textContent = editing ? `Edit ${editing.label}` : "Add address";
      html = `
        <div class="address-label-chips" role="group" aria-label="Address type">
          ${["Home", "Work", "Third party", "Other place"].map((label) => `
            <button class="${draftLabel === label ? "active" : ""}" type="button"
              data-sheet-action="address-label" data-address-label="${label}">${label}</button>`).join("")}
        </div>
        <div class="address-source-actions" role="group" aria-label="Choose address on a map">
          <button type="button" data-sheet-action="fill-current-address">
            <span aria-hidden="true">◎</span><b>Current location</b>
          </button>
          <button type="button" data-sheet-action="choose-map-pin">
            <span aria-hidden="true">⌖</span><b>Choose on map</b>
          </button>
          <button type="button" data-sheet-action="open-google-maps">
            <span aria-hidden="true">G</span><b>Google Maps</b>
          </button>
        </div>
        <div class="address-form">
          <label><span>Receiving person or business</span><input type="text" data-address-recipient
            value="${escapeHtml(draft.recipient || state.requestedRecipientName || "")}"
            placeholder="Full name" autocomplete="name" /></label>
          <label><span>Receiving contact</span><input type="tel" inputmode="tel" data-address-phone
            value="${escapeHtml(draft.phone || state.requestedRecipientPhone || "")}"
            placeholder="10-digit mobile" autocomplete="tel" /></label>
          <label class="wide"><span>House, building and street</span><textarea data-address-line
            placeholder="House number, building and street">${escapeHtml(draft.addressLine || "")}</textarea></label>
          <label><span>Area or locality</span><input type="text" data-address-area
            value="${escapeHtml(draftArea)}" placeholder="Area or locality" /></label>
          <label><span>PIN code</span><input type="text" inputmode="numeric" maxlength="6"
            data-address-pin value="${escapeHtml(draftPin)}" placeholder="6 digits" /></label>
          <label class="wide"><span>Landmark</span><input type="text" data-address-landmark
            value="${escapeHtml(draft.landmark || "")}" placeholder="Nearby landmark (optional)" /></label>
        </div>
        <button class="sheet-primary" type="button" data-sheet-action="save-address">
          Save and deliver here
        </button>`;
    }

    if (type === "address-request") {
      sheetKicker.textContent = "Third-party delivery";
      sheetTitle.textContent = "Request delivery address";
      html = `
        <label class="address-request-name">
          <span>Receiving person or business</span>
          <input type="text" data-address-request-name placeholder="Name or business" autocomplete="name" />
        </label>
        <label class="address-request-name">
          <span>Receiving contact</span>
          <input type="tel" inputmode="tel" data-address-request-phone
            placeholder="Mobile number" autocomplete="tel" />
        </label>
        <div class="address-request-note">
          <span aria-hidden="true">↗</span>
          <span><strong>They add or confirm the address</strong><small>The address returns to your saved delivery choices.</small></span>
        </div>
        <div class="address-share-actions" role="group" aria-label="Send address request">
          <button type="button" data-sheet-action="send-address-request" data-address-channel="WhatsApp">
            <span aria-hidden="true">WA</span><b>WhatsApp</b>
          </button>
          <button type="button" data-sheet-action="send-address-request" data-address-channel="MoolSocial">
            <span aria-hidden="true">M</span><b>MoolSocial</b>
          </button>
          <button type="button" data-sheet-action="send-address-request" data-address-channel="Share">
            <span aria-hidden="true">↗</span><b>More apps</b>
          </button>
        </div>
        <button class="sheet-secondary" type="button" data-sheet-action="enter-recipient-address">
          Enter address yourself
        </button>`;
    }

    if (type === "map-location") {
      const place = state.selectedMapPlace;
      sheetKicker.textContent = "Delivery location";
      sheetTitle.textContent = "Choose on map";
      html = `
        <label class="map-search">
          <span>Search place or landmark</span>
          <span><input type="search" data-map-search value="${escapeHtml(place.area)}"
            placeholder="Search area, street or landmark" /><button type="button"
            data-sheet-action="find-map-place">Find</button></span>
        </label>
        <button class="address-map-canvas" type="button" data-sheet-action="move-map-pin"
          aria-label="Move delivery pin">
          <span class="map-road one" aria-hidden="true"></span>
          <span class="map-road two" aria-hidden="true"></span>
          <span class="map-road three" aria-hidden="true"></span>
          <span class="map-pin" aria-hidden="true">●</span>
          <strong>Move the pin to the entrance</strong>
        </button>
        <div class="map-place-card">
          <span aria-hidden="true">⌖</span>
          <span><small>Selected delivery point</small><strong data-map-place-title>${escapeHtml(place.area)} · ${escapeHtml(place.pin)}</strong><em data-map-place-detail>${escapeHtml(place.addressLine)} · ${escapeHtml(place.landmark)}</em></span>
        </div>
        <button class="sheet-primary" type="button" data-sheet-action="use-map-pin">Use this pin</button>
        <button class="sheet-secondary" type="button" data-sheet-action="open-google-maps">Open Google Maps</button>`;
    }

    if (type === "share-apps") {
      sheetKicker.textContent = "Address request";
      sheetTitle.textContent = "Share with";
      html = `
        <div class="share-app-list" role="group" aria-label="Share address request">
          <button type="button" data-sheet-action="copy-address-request"><span aria-hidden="true">⧉</span><b>Copy request</b></button>
          <button type="button" data-sheet-action="email-address-request"><span aria-hidden="true">@</span><b>Email</b></button>
          <button type="button" data-sheet-action="message-address-request"><span aria-hidden="true">SMS</span><b>Messages</b></button>
        </div>`;
    }

    if (type === "confirm-address") {
      const contexts = cartAddressContexts();
      const combined = contexts.length > 1;
      const stats = cartScopeStats(state.cartScope);
      sheetKicker.textContent = "Before payment";
      sheetTitle.textContent = contexts.length > 1 ? "Confirm delivery addresses" : "Confirm delivery address";
      html = `
        <div class="address-confirm-list">
          ${contexts.map((context) => {
            const address = selectedAddress(context);
            return `
              <button type="button" data-sheet-action="change-confirm-address"
                data-address-context="${context}">
                <span class="address-mark" aria-hidden="true">${escapeHtml(address.label.slice(0, 1).toUpperCase())}</span>
                <span>
                  <small>${context === "business"
                    ? "Wholesale delivery"
                    : state.cartScope === "medicine" ? "Medicine delivery"
                      : state.cartScope === "shop" ? "Shop delivery" : "Shop and medicine delivery"}</small>
                  <strong>${escapeHtml(address.address)}</strong>
                  <em>${escapeHtml([address.detail, address.phone].filter(Boolean).join(" · "))}</em>
                </span>
                <b>Change</b>
              </button>`;
          }).join("")}
        </div>
        <div class="address-confirm-note">
          <span aria-hidden="true">✓</span>
          <span><strong>Delivery details checked</strong><small>You can still update the address before dispatch.</small></span>
        </div>
        <button class="sheet-primary address-confirm-primary" type="button"
          data-sheet-action="confirm-address-and-order">
          <span>${state.context === "business" && !combined ? "Confirm and place order" : "Confirm and pay"}</span>
          <strong>${money(stats.total)}</strong>
        </button>`;
    }

    if (type === "account") {
      sheetKicker.textContent = "MoolSocial account";
      sheetTitle.textContent = "Buying for";
      html = `
        <button class="account-option" type="button" data-sheet-action="choose-context" data-value="personal">
          <span>DC</span><span><strong>Myself</strong><small>Retail purchasing</small></span><span>${state.context === "personal" ? "Selected" : ""}</span>
        </button>
        <button class="account-option" type="button" data-sheet-action="choose-context" data-value="business">
          <span>SB</span><span><strong>Shree Balaji Retail</strong><small>Verified for wholesale purchasing</small></span><span>${state.context === "business" ? "Selected" : "Verified"}</span>
        </button>`;
    }

    if (type === "saved") {
      sheetKicker.textContent = state.context === "business" ? "Saved bulk orders" : "Saved items";
      sheetTitle.textContent = "Buy again";
      html = state.context === "business"
        ? `
          <button class="saved-option" type="button" data-sheet-action="open-saved" data-saved="business">
            <span><strong>Store restock</strong><small>Atta and sunflower oil · last ordered 12 days ago</small></span><b>2 items</b>
          </button>`
        : `
          <button class="saved-option" type="button" data-sheet-action="open-saved" data-saved="personal">
            <span><strong>Weekly essentials</strong><small>Tomatoes, atta and rice · last bought 8 days ago</small></span><b>3 items</b>
          </button>`;
    }

    if (type === "orders") {
      sheetKicker.textContent = "Orders";
      sheetTitle.textContent = "Purchases and delivery";
      html = `
        <button class="saved-option" type="button" data-sheet-action="open-order">
          <span><strong>${state.context === "business" ? "Purchase order PO-240782" : "Order MS-240782"}</strong><small>Preparing · delivery updates available</small></span><b>Track</b>
        </button>
        <button class="saved-option" type="button" data-sheet-action="open-delivered-order">
          <span><strong>${state.context === "business" ? "Store restock" : "Weekly essentials"}</strong><small>Delivered · reorder, change quantities or add products</small></span><b>Open</b>
        </button>`;
    }

    if (type === "order-assist") {
      const order = findOrder();
      sheetKicker.textContent = "Mool Assist";
      sheetTitle.textContent = "Orders, chat and calls";
      html = `
        <div class="assist-intro">
          <span aria-hidden="true">
            <svg viewBox="0 0 24 24"><path d="M5 5h14v11H9l-4 3z" /><path d="M8 9h8M8 12h5" /></svg>
          </span>
          <span>
            <strong>Get an answer or speak with MoolSocial</strong>
            <small>AI-assisted help uses your order status. Chat and calls stay inside MoolSocial.</small>
          </span>
        </div>
        <button class="assist-order" type="button" data-sheet-action="assist-track-order">
          <span class="order-kind ${order.kind}" aria-hidden="true">${orderKindMark(order)}</span>
          <span>
            <small>${order.number}</small>
            <strong>${order.state}</strong>
            <em>${order.date} · ${order.partner}</em>
          </span>
          <b>Track</b>
        </button>
        <div class="assist-quick" role="group" aria-label="Quick questions">
          <button type="button" data-assist-query="Where is my order?">Order status</button>
          <button type="button" data-assist-query="Change delivery">Change delivery</button>
          <button type="button" data-assist-query="Problem with an item">Item issue</button>
        </div>
        <label class="assist-question">
          <span>Ask Mool Assist</span>
          <input type="text" data-assist-input placeholder="Ask about an order" autocomplete="off" />
          <button type="button" data-sheet-action="assist-ask">Ask</button>
        </label>
        <div class="assist-response" data-assist-response role="status" aria-live="polite" hidden>
          <strong></strong><span></span>
        </div>
        <div class="assist-contact-actions">
          <button type="button" data-sheet-action="assist-chat">
            <svg viewBox="0 0 24 24" aria-hidden="true"><path d="M4 5h16v12H9l-5 4z" /><path d="M8 10h8M8 13h5" /></svg>
            <span><strong>Chat in app</strong><small>Continue with support</small></span>
          </button>
          <button type="button" data-sheet-action="assist-call">
            <svg viewBox="0 0 24 24" aria-hidden="true"><path d="M7 4 4 7c2 6 7 11 13 13l3-3-4-3-2 2c-3-1-5-3-6-6l2-2z" /></svg>
            <span><strong>Call in app</strong><small>Speak securely here</small></span>
          </button>
        </div>
        <div class="assist-chat-panel" data-assist-chat-panel hidden>
          <div class="assist-message incoming">
            <span aria-hidden="true">MA</span>
            <p><strong>Mool Assist</strong><small>I have this order and its latest status. How can I help?</small></p>
          </div>
          <div class="assist-chat-messages" data-assist-chat-messages aria-live="polite"></div>
          <label>
            <input type="text" data-assist-chat-input placeholder="Message MoolSocial support" autocomplete="off" />
            <button type="button" data-sheet-action="assist-chat-send">Send</button>
          </label>
        </div>`;
    }

    if (type === "scan") {
      sheetKicker.textContent = "Scan product";
      sheetTitle.textContent = "Place the code inside the frame";
      html = `
        <div class="scanner-surface">
          <div class="scan-frame" aria-hidden="true"></div>
          <strong>Ready to scan</strong>
          <small>Scan a barcode to find the matching product and available sellers.</small>
        </div>
        <button class="sheet-primary" type="button" data-sheet-action="scan-result">Choose a photo</button>`;
    }

    if (type === "medicine-detail") {
      const product = [...medicineProducts, prescriptionQuoteProduct].find(
        (item) => item.id === state.prescriptionProduct,
      ) || medicineProducts[0];
      const categoryName =
        medicineCategorySet.find((item) => item.id === product.category)?.label || "Health";
      const commitment = medicineCommitment(product);
      const approved = state.rxApprovedProductIds.has(product.id);
      const quantity = state.carts.personal.get(medicineCartKey(product.id))?.quantity || 0;
      const manufacturerFulfilment = !product.prescriptionRequired && [
        "vitamins",
        "first-aid",
        "devices",
        "baby-care",
        "skin-care",
      ].includes(product.category);
      const fulfilmentName = manufacturerFulfilment ? product.brand : product.seller;
      const fulfilmentType = manufacturerFulfilment ? "Manufacturer" : "Licensed pharmacy";
      const storage = product.category === "devices"
        ? "Keep dry and follow the manufacturer instructions"
        : "Store as directed on the pack and keep away from children";
      sheetKicker.textContent = `${categoryName} · ${product.brand}`;
      sheetTitle.textContent = product.title;
      html = `
        <div class="medicine-detail-hero">
          ${medicineVisual(product)}
          <span>
            <small>${product.prescriptionRequired
              ? approved ? "Prescription verified" : "Prescription required"
              : "No prescription required"}</small>
            <strong>${money(product.price)} <del>${money(product.mrp)}</del></strong>
            <em>${product.unit}</em>
          </span>
        </div>
        <div class="medicine-detail-facts">
          <span><small>Active ingredient</small><strong>${escapeHtml(product.composition)}</strong></span>
          <span><small>Pack</small><strong>${escapeHtml(product.pack)}</strong></span>
          <span><small>Brand / marketer</small><strong>${escapeHtml(product.brand)}</strong></span>
          <span><small>Sale requirement</small><strong>${product.prescriptionRequired
            ? approved ? "Approved for this order" : "Valid prescription and pharmacist check"
            : "Pack and label check before dispatch"}</strong></span>
          <span><small>Fulfilled by</small><strong>${escapeHtml(fulfilmentName)} · ${fulfilmentType}</strong></span>
          <span><small>Delivery</small><strong>${escapeHtml(commitment.delivery)} · ${escapeHtml(commitment.route)}</strong></span>
          <span><small>Storage</small><strong>${escapeHtml(storage)}</strong></span>
          <span><small>Order support</small><strong>Wrong, damaged or compromised pack support in MoolSocial</strong></span>
        </div>
        <div class="medicine-use-note">
          <span aria-hidden="true">i</span>
          <span><strong>Use safely</strong><small>Use prescription medicines only as directed by your doctor or pharmacist. Batch and expiry are checked before dispatch.</small></span>
        </div>
        <button class="sheet-primary" type="button"
          data-sheet-action="${quantity
            ? "medicine-detail-cart"
            : product.prescriptionRequired && !approved
              ? "medicine-detail-rx"
              : "medicine-detail-add"}">
          ${quantity
            ? `View Cart · ${quantity} ${quantity === 1 ? "pack" : "packs"}`
            : product.prescriptionRequired && !approved ? "Use a prescription" : "Add to Cart"}
        </button>
        <button class="sheet-secondary" type="button" data-sheet-action="medicine-detail-pharmacist">
          Ask a pharmacist
        </button>`;
    }

    if (type === "prescription") {
      const selectedMedicine = medicineProducts.find(
        (product) => product.id === state.prescriptionProduct,
      );
      sheetKicker.textContent = "Prescription";
      sheetTitle.textContent = selectedMedicine
        ? `Prescription for ${selectedMedicine.brand}`
        : "Add your prescription";
      html = `
        <div class="prescription-patient-card">
          <span aria-hidden="true">DC</span>
          <span><small>Prescription for</small><strong>Dharmendra Choudhary</strong><em>Deliver to Home · Sardarpura</em></span>
          <b>Me</b>
        </div>
        ${selectedMedicine
          ? `<div class="prescription-selected-medicine">
              <small>Requested medicine</small>
              <strong>${selectedMedicine.title}</strong>
              <span>${selectedMedicine.composition} · ${selectedMedicine.pack}</span>
            </div>`
          : ""}
        <div class="prescription-guidance">
          <strong>Choose a saved prescription or add a new one</strong>
          <span>Upload once. Every medicine listed on the prescription is linked for pharmacist review.</span>
        </div>
        ${savedPrescriptionOptionsHtml()}
        <div class="prescription-source-actions">
          <button class="sheet-option" type="button" data-sheet-action="prescription-added">
            <span><strong>Take a photo</strong><small>Use camera</small></span><b>Camera</b>
          </button>
          <button class="sheet-option" type="button" data-sheet-action="prescription-added">
            <span><strong>Choose a file</strong><small>JPG, PNG or PDF</small></span><b>Choose</b>
          </button>
        </div>`;
    }

    if (type === "past-prescriptions") {
      sheetKicker.textContent = "Prescriptions";
      sheetTitle.textContent = "Saved prescriptions";
      html = `
        <div class="prescription-guidance">
          <strong>Use a valid saved prescription</strong>
          <span>One review covers every medicine listed on the selected prescription.</span>
        </div>
        ${savedPrescriptionOptionsHtml()}
        <button class="sheet-option" type="button" data-sheet-action="new-prescription">
          <span><strong>Add a new prescription</strong><small>Take a photo or choose a file</small></span><b>Add</b>
        </button>`;
    }

    if (type === "pharmacist") {
      const selectedMedicine = medicineProducts.find(
        (product) => product.id === state.prescriptionProduct,
      );
      sheetKicker.textContent = "Licensed pharmacist";
      sheetTitle.textContent = "Medicine support";
      html = `
        <div class="pharmacist-profile">
          <span><small>Available now</small><strong>Speak with a licensed pharmacist</strong><em>Typical response in under 2 minutes</em></span>
          ${selectedMedicine
            ? `<span><small>Selected medicine</small><strong>${selectedMedicine.title}</strong><em>${selectedMedicine.composition} · ${selectedMedicine.pack}</em></span>`
            : `<span><small>Your conversation</small><strong>Medicine, dosage, prescription or refill</strong><em>Your prescription stays private</em></span>`}
        </div>
        <ul class="medicine-decision-list">
          <li><span><strong>Prescription check</strong><small>Medicine, strength and quantity</small></span><b>Available</b></li>
          <li><span><strong>Order guidance</strong><small>Pack, substitution and refill questions</small></span><b>No charge</b></li>
          <li><span><strong>Emergency symptoms</strong><small>Contact local emergency care immediately</small></span><b>Not supported</b></li>
        </ul>
        <button class="sheet-primary" type="button" data-sheet-action="pharmacist-chat">Chat with a pharmacist</button>
        <button class="sheet-secondary" type="button" data-sheet-action="pharmacist-call">Request a call</button>`;
    }

    if (type === "prescription-status") {
      const quoted = state.prescriptionState === "quoted";
      const selectedMedicine = medicineProducts.find(
        (product) => product.id === state.prescriptionProduct,
      );
      const coveredMedicines = prescriptionCoverageProducts();
      const coveredTotal = coveredMedicines.reduce(
        (total, medicine) => total + medicine.price,
        0,
      );
      sheetKicker.textContent = "Prescription";
      sheetTitle.textContent = quoted
        ? "Medicines verified"
        : "Review status";
      html = quoted
        ? coveredMedicines.length
          ? `
          <div class="prescription-quote">
            <span><small>Reviewed by a licensed pharmacist</small><strong>${money(coveredTotal)}</strong><em>${coveredMedicines.length} ${coveredMedicines.length === 1 ? "medicine" : "medicines"} linked to one prescription</em></span>
            <ul>
              ${coveredMedicines.map((medicine) => `
                <li><span><strong>${medicine.title}</strong><small>${medicine.composition} · ${medicine.pack}</small></span><b>${money(medicine.price)}</b></li>`).join("")}
            </ul>
          </div>
          <div class="prescription-quote-facts">
            <span><small>Prescription</small><strong>${state.selectedSavedPrescription || "Uploaded prescription"}</strong></span>
            <span><small>Pharmacy review</small><strong>Verified for these listed medicines</strong></span>
            <span><small>Next</small><strong>Add only the medicines you need</strong></span>
          </div>
          <button class="sheet-primary" type="button" data-sheet-action="prescription-view-medicines">
            View verified medicines
          </button>`
          : `
          <div class="prescription-quote">
            <span><small>RX-240728 · reviewed by a pharmacist</small><strong>₹684</strong><em>${medicineCommitment(prescriptionQuoteProduct).delivery} · after confirmation</em></span>
            <ul>
              <li><span><strong>Telmisartan 40 mg</strong><small>2 strips × 10 tablets</small></span><b>₹148</b></li>
              <li><span><strong>Metformin SR 500 mg</strong><small>3 strips × 10 tablets</small></span><b>₹396</b></li>
              <li><span><strong>Cholecalciferol 60,000 IU</strong><small>1 strip × 4 capsules</small></span><b>₹140</b></li>
            </ul>
          </div>
          <div class="prescription-quote-facts">
            <span><small>Pharmacy</small><strong>Sardarpura Health Pharmacy</strong></span>
            <span><small>Delivery</small><strong>${medicineCommitment(prescriptionQuoteProduct).delivery}</strong></span>
            <span><small>Prescription</small><strong>Verified for this order</strong></span>
          </div>
          <button class="sheet-primary" type="button" data-sheet-action="prescription-add-cart">Add quote to cart</button>`
        : `
          <div class="delivery-date-explainer">
            <span aria-hidden="true">✓</span>
            <span><strong>${coveredMedicines.length} ${coveredMedicines.length === 1 ? "medicine" : "medicines"} linked</strong><small>A pharmacist is checking every listed medicine, strength and quantity together.</small></span>
          </div>
          <ul class="prescription-linked-list">
            ${coveredMedicines.map((medicine) => `
              <li><span aria-hidden="true">Rx</span><strong>${medicine.title}</strong><b>Reviewing</b></li>`).join("")}
          </ul>
          <div class="slot-option active">
            <span><strong>One review in progress</strong><small>Reference RX-240728 · submitted today</small></span>
            <b>Up to 20 min</b>
          </div>
          <button class="sheet-primary" type="button" data-sheet-action="prescription-ready">
            ${selectedMedicine ? "View approval result" : "View reviewed quote"}
          </button>`;
    }

    if (type === "refill") {
      const refillDate = new Date();
      refillDate.setDate(refillDate.getDate() + 14);
      const refillDelivery = `${dayLabel(refillDate)} · by 8:30 pm`;
      sheetKicker.textContent = "Regular medicines";
      sheetTitle.textContent = "Refill plan";
      html = `
        <div class="medicine-refill-card">
          <span><small>Saved prescription</small><strong>Heart &amp; BP · Dr Meera Sharma</strong><em>Valid · issued 08 July 2026</em></span>
          <span><small>Next refill</small><strong>${dayLabel(refillDate)}</strong><em>Reminder 3 days before</em></span>
        </div>
        <ul class="medicine-decision-list">
          <li><span><strong>Telmisartan 40 mg</strong><small>2 strips × 10 tablets</small></span><b>₹148</b></li>
          <li><span><strong>Atorvastatin 10 mg</strong><small>2 strips × 10 tablets</small></span><b>₹108</b></li>
          <li><span><strong>Estimated delivery</strong><small>Reconfirmed before every payment</small></span><b>${refillDelivery}</b></li>
        </ul>
        <div class="delivery-date-explainer">
          <span aria-hidden="true">✓</span>
          <span><strong>You approve every refill</strong><small>Medicine, pack, quantity, final price and delivery are shown before an order is placed.</small></span>
        </div>
        <button class="sheet-primary" type="button" data-sheet-action="refill-created">
          ${state.refillState === "active" ? "Update refill reminder" : "Start refill reminders"}
        </button>
        <button class="sheet-secondary" type="button" data-sheet-action="refill-prescription">
          Choose another saved prescription
        </button>`;
    }

    if (type === "delivery-slot") {
      const commitments = cartCommitmentSummary();
      sheetKicker.textContent = state.context === "business" ? "Confirmed by suppliers" : "Confirmed by sellers";
      sheetTitle.textContent = state.context === "business" ? "Supplier deliveries" : "Delivery dates";
      html = commitments.lines
        .map(({ product, offer }) => `
          <div class="slot-option active">
            <span>
              <strong>${product.title}</strong>
              <small>${offer.seller} · ${offer.commitment.route}</small>
              <small>Order by ${offer.commitment.orderBy} · dispatch ${offer.commitment.dispatch}</small>
            </span>
            <b>${offer.commitment.delivery}</b>
          </div>`)
        .join("");
    }

    sheetContent.innerHTML = html;
    sheetLayer.hidden = false;
    document.body.style.overflow = "hidden";
    setTimeout(() => sheetLayer.querySelector("button, input")?.focus(), 0);
  };

  const finishSheetClose = () => {
    sheetLayer.hidden = true;
    sheet.classList.remove("is-dragging", "is-settling", "is-dismissing");
    sheet.style.removeProperty("--sheet-drag-y");
    document.body.style.overflow = "";
    if (query().has("sheet")) setUrl({ sheet: null }, false);
    setDock(visibleView());
  };

  const closeSheet = ({ animate = false } = {}) => {
    if (sheetLayer.hidden) return;
    clearTimeout(sheetCloseTimer);
    if (animate && !window.matchMedia("(prefers-reduced-motion: reduce)").matches) {
      sheet.classList.remove("is-dragging", "is-settling");
      sheet.classList.add("is-dismissing");
      sheetCloseTimer = setTimeout(finishSheetClose, 180);
      return;
    }
    finishSheetClose();
  };

  const updateFilterLens = (surface) => {
    const lens = sheetContent.querySelector("[data-filter-lens]");
    if (!lens || lens.dataset.filterSurface !== surface) return;
    const filters = state.filters[surface];
    lens.querySelectorAll("[data-filter-group]").forEach((button) => {
      const active = filters[button.dataset.filterGroup] === button.dataset.filterValue;
      button.classList.toggle("active", active);
      button.setAttribute("aria-checked", String(active));
    });
    const summary = lens.querySelector("[data-filter-selection-summary]");
    if (summary) summary.textContent = filterSummary(surface, { includeDefaults: true });
    const resultCount = lens.querySelector("[data-filter-result-count]");
    if (resultCount) {
      const profile = filterProfiles[surface];
      resultCount.textContent = `${filterResultCount(surface)} ${profile.resultLabel}`;
    }
  };

  const applyActiveFilter = ({ close = true } = {}) => {
    const surface = state.filterSurface === "medicine" ? "medicine" : state.context;
    if (surface === "medicine") renderMedicine();
    else renderProducts();
    renderFilterStatus(surface);
    updateFilterLens(surface);
    if (close) closeSheet();
  };

  const answerAssist = (question) => {
    const input = sheetContent.querySelector("[data-assist-input]");
    const response = sheetContent.querySelector("[data-assist-response]");
    const order = findOrder();
    const normalizedQuestion = question.trim();
    if (!normalizedQuestion) {
      input?.focus();
      showToast("Ask a question about your order");
      return false;
    }
    if (input) input.value = normalizedQuestion;
    response.hidden = false;
    response.querySelector("strong").textContent = `${order.state} · ${order.date}`;
    response.querySelector("span").textContent =
      /change|address|time|delivery/i.test(normalizedQuestion)
        ? `Mool Assist can check available changes with ${order.partner}. Your current commitment remains protected until you confirm.`
        : /problem|issue|missing|damage|wrong/i.test(normalizedQuestion)
          ? `I can start an item-resolution request for ${order.number}. Chat or call support in app if you need a person.`
          : `Order ${order.number} is being fulfilled by ${order.partner}, ${order.partnerType}. Open tracking for every live update.`;
    response.scrollIntoView({ block: "nearest", behavior: "smooth" });
    return true;
  };

  const showNotice = ({ icon = "!", kicker, title, message, actions }) => {
    document.querySelector("[data-notice-icon]").textContent = icon;
    document.querySelector("[data-notice-kicker]").textContent = kicker;
    document.querySelector("[data-notice-title]").textContent = title;
    document.querySelector("[data-notice-message]").textContent = message;
    document.querySelector("[data-notice-actions]").innerHTML = actions
      .map(({ label, action }) => `<button type="button" data-notice-action="${action}">${label}</button>`)
      .join("");
    noticeLayer.hidden = false;
    document.body.style.overflow = "hidden";
    setTimeout(() => noticeLayer.querySelector("button")?.focus(), 0);
  };

  const closeNotice = () => {
    noticeLayer.hidden = true;
    document.body.style.overflow = "";
  };

  const showCondition = (condition) => {
    if (condition === "price") {
      showNotice({
        icon: "₹",
        kicker: state.context === "business" ? "Bulk order update" : "Cart update",
        title: "Price updated",
        message: "The final delivered price for stone-ground wheat atta changed from ₹279 to ₹284. Nothing has been charged.",
        actions: [
          { label: "Use new price", action: "accept-price" },
          { label: "Remove item", action: "remove-atta" },
        ],
      });
    }
    if (condition === "stock") {
      showNotice({
        icon: "↻",
        kicker: "Availability update",
        title: "Selected pack is unavailable",
        message: "The 5 L sunflower oil can sold out at Ghar Bazaar. Another verified seller can deliver it today for ₹849.",
        actions: [
          { label: "Choose another seller", action: "alternate-seller" },
          { label: "Remove item", action: "remove-oil" },
        ],
      });
    }
    if (condition === "unavailable") {
      showNotice({
        icon: "⌖",
        kicker: "Delivery area",
        title: "We don't deliver here yet",
        message: state.context === "business"
          ? "No verified supplier can currently serve this bulk order for PIN code 110001. Your selections remain saved."
          : "No verified seller can currently deliver this cart to PIN code 110001. Your cart is still saved.",
        actions: [
          { label: "Change PIN code", action: "change-pin" },
          { label: "Notify me", action: "notify-area" },
        ],
      });
    }
    if (condition === "payment") {
      showNotice({
        icon: "!",
        kicker: "Payment",
        title: "Payment was not completed",
        message: "No amount was charged. Your Cart, prices and delivery commitments are still available.",
        actions: [
          { label: "Try again", action: "retry-payment" },
          { label: "Choose another method", action: "payment-method" },
        ],
      });
    }
    if (condition === "network") {
      showNotice({
        icon: "↻",
        kicker: "Connection",
        title: "We couldn't refresh this page",
        message: "Your Cart and selected quantities are saved on this device.",
        actions: [
          { label: "Try again", action: "retry-network" },
          { label: "Continue offline", action: "continue-offline" },
        ],
      });
    }
    if (condition === "delivery") {
      showNotice({
        icon: "⌚",
        kicker: "Delivery update",
        title: "Delivery is running late",
        message: "The seller now expects delivery by 9:00 pm. You can keep the order or contact support.",
        actions: [
          { label: "Keep order", action: "keep-order" },
          { label: "Mool Assist", action: "order-help" },
        ],
      });
    }
  };

  const cartAddressContexts = (scope = state.cartScope) => {
    if (scope === "wholesale") return ["business"];
    if (scope !== "all") return ["personal"];
    return [
      personalCartLines().length ? "personal" : null,
      wholesaleCartLines().length ? "business" : null,
    ].filter(Boolean);
  };

  const addressConfirmationSignature = () => {
    const scope = normalizedCartScope(state.cartScope) || "shop";
    return [
      scope,
      ...cartAddressContexts(scope)
      .map((context) => `${context}:${state.selectedAddressIds[context]}`)
    ].join("|");
  };

  const purchaseOrderTermsConfirmed = () => {
    const combined = visibleView() === "basket"
      && state.cartScope === "all"
      && wholesaleCartLines().length > 0;
    const consent = combined
      ? document.querySelector("[data-combined-cart-consent]")
      : visibleView() === "basket"
        ? document.querySelector("[data-cart-po-consent]")
        : document.querySelector("[data-po-consent]");
    const wholesalePurchase = combined || state.cartScope === "wholesale";
    if (wholesalePurchase && !consent?.checked) {
      showToast("Confirm the purchase order terms to continue");
      consent?.focus();
      return false;
    }
    return true;
  };

  const completeOrder = () => {
    const scope = normalizedCartScope(state.cartScope) || "shop";
    state.addressConfirmationKey = addressConfirmationSignature();
    state.lastConfirmationScope = scope;
    state.context = scope === "wholesale" ? "business" : "personal";
    if (scope === "all") {
      state.lastOrders.personal = cloneOrder(cart("personal"));
      state.lastOrders.business = cloneOrder(cart("business"));
    } else if (scope === "wholesale") {
      state.lastOrders.business = cloneCartScope("wholesale");
    } else {
      state.lastOrders.personal = cloneCartScope(scope);
    }
    setUrl({ confirm: state.lastConfirmationScope }, false);
    showView("confirmed");
  };

  const requestOrderPlacement = () => {
    if (!purchaseOrderTermsConfirmed()) return;
    if (state.addressConfirmationKey === addressConfirmationSignature()) {
      completeOrder();
      return;
    }
    openSheet("confirm-address");
  };

  const restoreFromUrl = () => {
    const params = query();
    const previousView = visibleView();
    const requestedOrderId = params.get("order");
    const requestedOrder = orderRecords().find((order) => order.id === requestedOrderId);
    state.context = requestedOrder
      ? requestedOrder.context
      : params.get("context") === "business" ? "business" : "personal";
    if (requestedOrder) state.activeOrderId = requestedOrder.id;
    state.ordersTab = params.get("orders") === "delivered" ? "delivered" : "active";
    const confirmationScope = params.get("confirm") || params.get("cart");
    state.lastConfirmationScope = normalizedCartScope(confirmationScope)
      || (
        reviewSeed === "combined-cart" || reviewSeed === "mixed-cart"
          ? "all"
          : reviewSeed === "medicine-cart"
            ? "medicine"
            : state.context === "business" ? "wholesale" : "shop"
      );
    if (params.get("prescription") === "quote") state.prescriptionState = "quoted";
    else if (params.get("prescription") === "review") state.prescriptionState = "review";
    const requestedMedicineProduct = medicineProducts.find(
      (product) => product.id === params.get("medicine"),
    );
    if (requestedMedicineProduct) {
      state.prescriptionProduct = requestedMedicineProduct.id;
      if (["review", "quoted"].includes(state.prescriptionState)) {
        const matchingRecord = savedPrescriptionRecords.find((record) =>
          record.productIds.includes(requestedMedicineProduct.id));
        state.selectedSavedPrescription =
          matchingRecord?.name || state.selectedSavedPrescription;
        setPrescriptionCoverage(
          matchingRecord?.productIds
            || relatedPrescriptionProductIds(requestedMedicineProduct.id),
        );
      }
      if (state.prescriptionState === "quoted") {
        approvePrescriptionCoverage();
      }
    }
    const requestedMedicineCategory = params.get("med");
    state.medicineCategory =
      requestedMedicineCategory === "rx" ||
      medicineCategorySet.some((category) => category.id === requestedMedicineCategory)
        ? requestedMedicineCategory
        : "all";
    const requestedCartScope = params.get("cart");
    state.cartScope = normalizedCartScope(requestedCartScope)
      || (
        reviewSeed === "combined-cart" || reviewSeed === "mixed-cart"
          ? "all"
          : reviewSeed === "medicine-cart"
            ? "medicine"
            : state.context === "business" ? "wholesale" : "shop"
      );
    const requestedCartReturn = params.get("cartReturn");
    state.cartReturnView = ["retail", "wholesale", "medicine"].includes(requestedCartReturn)
      ? requestedCartReturn
      : reviewSeed === "medicine-cart"
        ? "medicine"
        : state.context === "business" ? "wholesale" : "retail";
    discovery().category = isCategoryAvailable(params.get("category"))
      ? params.get("category")
      : "all";
    discovery().subcategory = isSubcategoryAvailable(params.get("sub"))
      ? params.get("sub") || "all"
      : "all";
    discovery().search = params.get("q") || "";
    const productId = params.get("product");
    state.currentProduct = products.find((product) => product.id === productId) || products[0];
    renderContext();
    const requestedView = ["product", "medicine", "basket", "checkout", "confirmed", "orders", "tracking"].includes(params.get("view"))
      ? params.get("view")
      : "catalogue";
    const view = requestedView === "checkout" ? "basket" : requestedView;
    if (view === "product") renderProduct();
    showView(view, {
      push: false,
      restoreCatalogueScroll: view === "catalogue" && previousView === "product",
    });
    const requestedSheet = params.get("sheet");
    if (requestedSheet === "orders") {
      setUrl({ sheet: null, view: "orders" }, false);
      showView("orders", { push: false });
    } else if (requestedSheet === "assist") {
      openSheet("order-assist");
    } else if ([
      "location",
      "address-form",
      "address-request",
      "confirm-address",
      "map-location",
      "share-apps",
      "medicine-detail",
      "prescription-status",
      "filters",
    ].includes(requestedSheet)) {
      state.addressContext = params.get("address") === "business" ? "business" : "personal";
      if (requestedSheet === "medicine-detail") {
        state.prescriptionProduct = params.get("medicine") || medicineProducts[0].id;
      }
      if (requestedSheet === "filters") {
        state.filterSurface = view === "medicine" ? "medicine" : state.context;
      }
      openSheet(requestedSheet);
    } else if (!sheetLayer.hidden) {
      closeSheet();
    }
    const condition = params.get("condition");
    if (condition) setTimeout(() => showCondition(condition), 120);
  };

  app.addEventListener("click", (event) => {
    const button = event.target.closest("button, [role='button']");
    if (!button) return;
    if (suppressContextClick) {
      event.preventDefault();
      return;
    }
    if (button.dataset.medicineCategory) {
      state.medicineCategory = button.dataset.medicineCategory;
      state.medicineCategoryRailExpanded = false;
      medicineSearch.value = "";
      setUrl({
        med: state.medicineCategory === "all" ? null : state.medicineCategory,
      }, false);
      renderMedicine();
      hapticTick();
      return;
    }

    if (button.dataset.medicineProductId) {
      state.prescriptionProduct = button.dataset.medicineProductId;
      setUrl({ medicine: state.prescriptionProduct }, false);
      openSheet("medicine-detail");
      return;
    }

    if (button.dataset.medicineAdd) {
      addMedicineToCart(button.dataset.medicineAdd);
      return;
    }

    if (button.dataset.medicineIncrease) {
      changeCartQuantity(medicineCartKey(button.dataset.medicineIncrease), 1, "personal");
      return;
    }

    if (button.dataset.medicineDecrease) {
      changeCartQuantity(medicineCartKey(button.dataset.medicineDecrease), -1, "personal");
      return;
    }

    if (button.dataset.ordersTab) {
      state.ordersTab = button.dataset.ordersTab;
      setUrl({ orders: state.ordersTab === "delivered" ? "delivered" : null }, false);
      renderOrders();
      hapticTick();
      return;
    }

    if (button.dataset.openOrder) {
      openOrder(button.dataset.openOrder);
      return;
    }

    if (button.dataset.reorderOrder) {
      const order = findOrder(button.dataset.reorderOrder);
      state.context = order.context;
      state.activeOrderId = order.id;
      renderContext();
      openReorder(order);
      return;
    }

    if (button.dataset.cartScope) {
      const scope = button.dataset.cartScope;
      if (!["all", "shop", "wholesale", "medicine"].includes(scope)) return;
      state.cartScope = scope;
      if (scope === "wholesale") state.cartReturnView = "wholesale";
      if (scope === "shop") state.cartReturnView = "retail";
      if (scope === "medicine") state.cartReturnView = "medicine";
      if (scope !== "all") {
        const nextContext = scope === "wholesale" ? "business" : "personal";
        if (nextContext !== state.context) {
          setContext(nextContext, { push: false });
        }
      }
      setUrl({
        cart: scope,
        cartReturn: state.cartReturnView,
        context: state.context === "business" ? "business" : null,
      }, false);
      renderBasket();
      hapticTick();
      return;
    }

    if (button.dataset.context) {
      if (button.dataset.context === state.context) {
        if (visibleView() !== "catalogue") showView("catalogue");
        return;
      }
      setContext(button.dataset.context);
      return;
    }

    if (button.dataset.categoryView) {
      showView(button.dataset.categoryView);
      return;
    }

    if (button.dataset.category) {
      selectCategory(button.dataset.category);
      return;
    }

    if (button.dataset.subcategory) {
      discovery().subcategory = button.dataset.subcategory;
      setUrl({ sub: discovery().subcategory === "all" ? null : discovery().subcategory });
      renderProducts();
      return;
    }

    if (button.dataset.productId) {
      openProduct(button.dataset.productId);
      return;
    }

    if (button.dataset.wholesalePreview) {
      event.stopPropagation();
      const productId = button.dataset.wholesalePreview;
      setContext("business", { push: false });
      openProduct(productId);
      return;
    }

    if (button.dataset.add) {
      event.stopPropagation();
      addToCart(button.dataset.add, 1, 0);
      renderProducts();
      return;
    }

    if (button.dataset.cardIncrease) {
      event.stopPropagation();
      changeCartQuantity(
        button.dataset.cardIncrease,
        1,
        button.dataset.cartContext || state.context,
      );
      return;
    }

    if (button.dataset.cardDecrease) {
      event.stopPropagation();
      changeCartQuantity(
        button.dataset.cardDecrease,
        -1,
        button.dataset.cartContext || state.context,
      );
      return;
    }

    if (button.dataset.householdMemberIncrease) {
      changeHouseholdBasketMembers(button.dataset.householdMemberIncrease, 1);
      return;
    }

    if (button.dataset.householdMemberDecrease) {
      changeHouseholdBasketMembers(button.dataset.householdMemberDecrease, -1);
      return;
    }

    if (button.dataset.packIndex !== undefined) {
      state.selectedPack = Number(button.dataset.packIndex);
      state.sellerChoices[state.context].delete(state.currentProduct.id);
      state.quantity = minimumQuantity();
      renderProduct();
      return;
    }

    if (button.dataset.remove) {
      state.addressConfirmationKey = null;
      cart(button.dataset.cartContext || state.context).delete(button.dataset.remove);
      renderBasket();
      updateCartSurfaces();
      renderHouseholdBasketOffer();
      return;
    }

    if (button.dataset.payment) {
      state.payment = button.dataset.payment;
      if (visibleView() === "basket") renderBasket();
      if (visibleView() === "checkout") renderCheckout();
      return;
    }

    if (button.dataset.nav) {
      if (button.dataset.nav === "retail") {
        if (state.context !== "personal") setContext("personal", { push: false });
        showView("catalogue");
      }
      if (button.dataset.nav === "wholesale") {
        if (state.context !== "business") setContext("business", { push: false });
        showView("catalogue");
      }
      if (button.dataset.nav === "medicine") {
        if (state.context !== "personal") setContext("personal", { push: false });
        showView("medicine");
      }
      if (button.dataset.nav === "orders") showView("orders");
      return;
    }

    const action = button.dataset.action;
    if (!action) return;

    if (action === "saved") openSheet("saved");
    if (action === "account") openSheet("account");
    if (action === "location" || action === "change-address") {
      state.addressContext = button.dataset.addressContext
        || (visibleView() === "basket" && state.cartScope === "wholesale" ? "business" : state.context);
      openSheet("location");
    }
    if (action === "filters") {
      state.filterSurface = button.dataset.filterSurface === "medicine"
        || visibleView() === "medicine"
        ? "medicine"
        : state.context;
      openSheet("filters");
    }
    if (action === "category-more" || action === "category-less") {
      state.categoryRailExpanded[state.context] = action === "category-more";
      renderCategories();
      renderProducts();
      hapticTick();
    }
    if (action === "scan") openSheet("scan");
    if (action === "compare") openSheet("compare");
    if (action === "upload-prescription") {
      state.prescriptionProduct = button.dataset.rxProduct || null;
      state.prescriptionMatchedProductIds = new Set();
      state.selectedSavedPrescription = "";
      openSheet("prescription");
    }
    if (action === "past-prescriptions") {
      state.prescriptionProduct = button.dataset.rxProduct || state.prescriptionProduct;
      openSheet("past-prescriptions");
    }
    if (action === "prescription-status") openSheet("prescription-status");
    if (action === "medicine-category-more" || action === "medicine-category-less") {
      state.medicineCategoryRailExpanded = action === "medicine-category-more";
      renderMedicine();
      hapticTick();
    }
    if (action === "delivery-slot") openSheet("delivery-slot");
    if (action === "toggle-household-basket") {
      state.householdBasketExpanded = !state.householdBasketExpanded;
      renderHouseholdBasketOffer();
      hapticTick();
    }
    if (action === "add-household-basket") {
      addHouseholdBasketToCart(button.dataset.householdBasketId);
    }
    if (action === "close-sheet") closeSheet({ animate: true });
    if (action === "clear-search" || action === "reset-search") {
      discovery().search = "";
      search.value = "";
      clearSearch.hidden = true;
      setUrl({ q: null }, false);
      renderProducts();
      search.focus();
    }
    if (action === "clear-filter") {
      const surface = button.dataset.filterSurface === "medicine"
        || visibleView() === "medicine"
        ? "medicine"
        : state.context;
      state.filters[surface] = { timing: "anytime", price: "", term: "" };
      state.filterSurface = surface;
      if (surface === "medicine") renderMedicine();
      else renderProducts();
      showToast(`${filterProfiles[surface].kicker} filters cleared`);
    }
    if (action === "catalogue") showView("catalogue");
    if (action === "add-products") {
      if (state.cartScope === "medicine"
        || (state.cartScope === "all" && state.cartReturnView === "medicine")) {
        state.context = "personal";
        showView("medicine");
      } else {
        state.context = state.cartScope === "wholesale"
          || (state.cartScope === "all" && state.cartReturnView === "wholesale")
          ? "business"
          : "personal";
        renderContext();
        showView("catalogue");
      }
    }
    if (action === "track-live-order") openOrder(state.liveOrderId || "retail-active");
    if (action === "back") window.history.length > 1 ? window.history.back() : showView("catalogue");
    if (action === "basket") {
      rememberCartReturnView();
      const availableScopes = availableCartScopes();
      state.cartScope = availableScopes.length > 1
        ? "all"
        : availableScopes[0] || (state.context === "business" ? "wholesale" : "shop");
      showView("basket");
    }
    if (action === "checkout") {
      if (cartStats().count === 0) showToast("Add a product before checkout");
      else {
        rememberCartReturnView();
        showView("basket");
      }
    }
    if (action === "increase") {
      state.quantity += 1;
      updateQuantity();
    }
    if (action === "decrease") {
      state.quantity = Math.max(minimumQuantity(), state.quantity - 1);
      updateQuantity();
    }
    if (action === "add-detail") {
      state.addressConfirmationKey = null;
      if (cart().has(state.currentProduct.id)) {
        cart().set(state.currentProduct.id, {
          quantity: state.quantity,
          packIndex: state.selectedPack,
        });
        announceCartAddition(state.currentProduct.title);
      } else {
        addToCart(state.currentProduct.id, state.quantity, state.selectedPack);
      }
      updateQuantity();
    }
    if (action === "save-product") showToast(`${state.currentProduct.title} saved`);
    if (action === "clear-basket") {
      state.addressConfirmationKey = null;
      clearCartScope(state.cartScope);
      renderBasket();
      updateCartSurfaces();
    }
    if (action === "pharmacist") {
      state.prescriptionProduct = button.dataset.rxProduct || state.prescriptionProduct;
      openSheet("pharmacist");
    }
    if (action === "orders-help") {
      openSheet("order-assist");
    }
    if (action === "start-refill") openSheet("refill");
    if (action === "confirm-order") {
      requestOrderPlacement();
    }
    if (action === "track-order") showView("tracking");
    if (action === "confirmation") showView("confirmed");
    if (action === "orders") {
      showView("orders");
    }
    if (action === "reorder") openReorder(findOrder());
    if (action === "continue-shopping") {
      state.addressConfirmationKey = null;
      clearCartScope(state.lastConfirmationScope);
      updateCartSurfaces();
      renderProducts();
      showView(state.lastConfirmationScope === "medicine" ? "medicine" : "catalogue");
    }
  });

  const captureAddressDraft = () => ({
    label: normalizeAddressTypeLabel(state.addressDraftLabel || "Other place"),
    recipient: sheetContent.querySelector("[data-address-recipient]")?.value.trim() || "",
    phone: sheetContent.querySelector("[data-address-phone]")?.value.trim() || "",
    addressLine: sheetContent.querySelector("[data-address-line]")?.value.trim() || "",
    landmark: sheetContent.querySelector("[data-address-landmark]")?.value.trim() || "",
    area: sheetContent.querySelector("[data-address-area]")?.value.trim() || "",
    pin: sheetContent.querySelector("[data-address-pin]")?.value.trim() || "",
    mapsLink: state.addressDraft?.mapsLink || "",
  });

  const addressRequestMessage = () => {
    const recipient = state.requestedRecipientName || "there";
    return `Hi ${recipient}, please share or confirm your delivery address for this MoolSocial order.`;
  };

  sheetContent.addEventListener("click", (event) => {
    const button = event.target.closest("button");
    if (!button) return;

    if (button.dataset.sheetCategory) {
      closeSheet();
      showView("catalogue", { push: false });
      selectCategory(button.dataset.sheetCategory);
      return;
    }

    if (button.dataset.sheetView) {
      closeSheet();
      showView(button.dataset.sheetView);
      return;
    }

    if (button.dataset.filterGroup && button.dataset.filterValue !== undefined) {
      const surface = state.filterSurface === "medicine" ? "medicine" : state.context;
      state.filters[surface][button.dataset.filterGroup] = button.dataset.filterValue;
      applyActiveFilter({ close: false });
      hapticTick();
      return;
    }

    if (button.dataset.filterReset) {
      const surface = button.dataset.filterReset;
      state.filters[surface] = { timing: "anytime", price: "", term: "" };
      state.filterSurface = surface;
      applyActiveFilter({ close: false });
      hapticTick();
      return;
    }

    if (button.dataset.sellerIndex !== undefined) {
      const selectedIndex = Number(button.dataset.sellerIndex);
      const seller = state.currentProduct[state.context].sellers[selectedIndex];
      state.sellerChoices[state.context].set(state.currentProduct.id, selectedIndex);
      renderProduct();
      closeSheet();
      showToast(`${seller[1]} selected`);
      return;
    }

    if (button.dataset.assistQuery) {
      answerAssist(button.dataset.assistQuery);
      return;
    }

    const action = button.dataset.sheetAction;
    if (!action) return;

    if (action === "select-address") {
      const context = button.dataset.addressContext || state.addressContext;
      if (!selectAddress(context, button.dataset.addressId)) return;
      renderLocation();
      if (visibleView() === "basket") renderBasket();
      if (visibleView() === "checkout") renderCheckout();
      if (state.returnToAddressConfirmation) {
        state.returnToAddressConfirmation = false;
        openSheet("confirm-address");
      } else {
        closeSheet();
        showToast("Delivery address selected");
      }
      return;
    }
    if (action === "edit-address") {
      state.addressContext = button.dataset.addressContext || state.addressContext;
      state.editingAddressId = button.dataset.addressId;
      state.addressDraft = null;
      state.addressDraftLabel =
        state.addressBook[state.addressContext].find((address) => address.id === state.editingAddressId)?.label
        || "Other place";
      openSheet("address-form");
      return;
    }
    if (action === "new-address") {
      state.editingAddressId = null;
      state.addressDraftLabel = "Other place";
      state.addressDraft = null;
      openSheet("address-form");
      return;
    }
    if (action === "address-label") {
      state.addressDraftLabel = normalizeAddressTypeLabel(
        button.dataset.addressLabel || "Other place",
      );
      sheetContent.querySelectorAll("[data-address-label]").forEach((option) => {
        option.classList.toggle("active", option === button);
      });
      return;
    }
    if (action === "fill-current-address" || action === "use-current-address") {
      if (action === "use-current-address") {
        state.editingAddressId = null;
        state.addressDraftLabel = "Other place";
        state.addressDraft = null;
        openSheet("address-form");
      }
      const recipient = sheetContent.querySelector("[data-address-recipient]");
      const phone = sheetContent.querySelector("[data-address-phone]");
      const addressLine = sheetContent.querySelector("[data-address-line]");
      const landmark = sheetContent.querySelector("[data-address-landmark]");
      const pin = sheetContent.querySelector("[data-address-pin]");
      const area = sheetContent.querySelector("[data-address-area]");
      if (recipient && !recipient.value) recipient.value =
        state.addressContext === "business" ? "Shree Balaji Retail" : "Dharmendra Choudhary";
      if (phone && !phone.value && state.addressContext === "business") phone.value = "+91 92518 93684";
      if (addressLine) addressLine.value = "Residency Road, Sardarpura";
      if (landmark) landmark.value = "Near Sardarpura Circle";
      if (pin) pin.value = "342003";
      if (area) area.value = "Sardarpura";
      addressLine?.focus();
      showToast("Current area added · check the details");
      return;
    }
    if (action === "choose-map-pin") {
      state.addressDraft = captureAddressDraft();
      openSheet("map-location");
      return;
    }
    if (action === "open-google-maps") {
      if (sheetContent.querySelector("[data-address-recipient]")) {
        state.addressDraft = captureAddressDraft();
      }
      const queryText = sheetContent.querySelector("[data-map-search]")?.value.trim()
        || state.addressDraft?.area
        || state.selectedMapPlace.area;
      window.open(
        `https://www.google.com/maps/search/?api=1&query=${encodeURIComponent(queryText)}`,
        "_blank",
        "noopener,noreferrer",
      );
      return;
    }
    if (action === "find-map-place") {
      const searchValue = sheetContent.querySelector("[data-map-search]")?.value.trim();
      if (!searchValue) {
        showToast("Enter a place or landmark");
        sheetContent.querySelector("[data-map-search]")?.focus();
        return;
      }
      state.selectedMapPlace = {
        ...state.selectedMapPlace,
        addressLine: searchValue,
        landmark: "Entrance selected on map",
        area: searchValue,
        mapsLink: `https://maps.google.com/?q=${encodeURIComponent(searchValue)}`,
      };
      sheetContent.querySelector("[data-map-place-title]").textContent =
        `${state.selectedMapPlace.area} · ${state.selectedMapPlace.pin}`;
      sheetContent.querySelector("[data-map-place-detail]").textContent =
        `${state.selectedMapPlace.addressLine} · ${state.selectedMapPlace.landmark}`;
      showToast("Map moved to the searched place");
      return;
    }
    if (action === "move-map-pin") {
      state.selectedMapPlace = {
        ...state.selectedMapPlace,
        landmark: "Entrance pin selected",
      };
      sheetContent.querySelector("[data-map-place-detail]").textContent =
        `${state.selectedMapPlace.addressLine} · ${state.selectedMapPlace.landmark}`;
      showToast("Delivery pin moved");
      return;
    }
    if (action === "use-map-pin") {
      state.addressDraft = {
        ...(state.addressDraft || {}),
        ...state.selectedMapPlace,
      };
      openSheet("address-form");
      return;
    }
    if (action === "save-address") {
      const recipient = sheetContent.querySelector("[data-address-recipient]")?.value.trim();
      const phone = sheetContent.querySelector("[data-address-phone]")?.value.trim();
      const addressLine = sheetContent.querySelector("[data-address-line]")?.value.trim();
      const landmark = sheetContent.querySelector("[data-address-landmark]")?.value.trim();
      const pin = sheetContent.querySelector("[data-address-pin]")?.value.trim();
      const area = sheetContent.querySelector("[data-address-area]")?.value.trim();
      const phoneDigits = (phone || "").replace(/\D/g, "");
      if (!recipient || phoneDigits.length < 10 || phoneDigits.length > 13 || !addressLine || !/^\d{6}$/.test(pin) || !area) {
        showToast("Add receiving person, contact, address, area and a 6-digit PIN");
        sheetContent.querySelector(
          !recipient ? "[data-address-recipient]"
            : phoneDigits.length < 10 || phoneDigits.length > 13 ? "[data-address-phone]"
              : !addressLine ? "[data-address-line]"
              : !/^\d{6}$/.test(pin) ? "[data-address-pin]" : "[data-address-area]",
        )?.focus();
        return;
      }
      const label = normalizeAddressTypeLabel(state.addressDraftLabel || "Other place");
      const addressId = state.editingAddressId
        || `${label.toLowerCase().replace(/\s+/g, "-")}-${Date.now()}`;
      const displayAddress = label === "Home" || label === "Work"
        ? `${label} · ${area}`
        : label === "Third party"
          ? `${recipient.split(" ")[0]} · ${area}`
          : `Other place · ${area}`;
      const normalizedDetail = [
        addressLine,
        landmark,
        area,
        pin,
      ].filter(Boolean).join(", ");
      const savedAddress = {
        id: addressId,
        label,
        recipient,
        phone,
        addressLine,
        landmark,
        mapsLink: state.addressDraft?.mapsLink || "",
        area: `${area} · ${pin}`,
        address: displayAddress,
        detail: normalizedDetail,
      };
      const addresses = state.addressBook[state.addressContext];
      const existingIndex = addresses.findIndex((address) => address.id === addressId);
      if (existingIndex >= 0) addresses.splice(existingIndex, 1, savedAddress);
      else addresses.push(savedAddress);
      selectAddress(state.addressContext, addressId);
      state.editingAddressId = null;
      state.addressDraftLabel = "Other place";
      state.addressDraft = null;
      state.requestedRecipientName = "";
      state.requestedRecipientPhone = "";
      renderLocation();
      if (visibleView() === "basket") renderBasket();
      if (visibleView() === "checkout") renderCheckout();
      if (state.returnToAddressConfirmation) {
        state.returnToAddressConfirmation = false;
        openSheet("confirm-address");
      } else {
        closeSheet();
        showToast("Address saved");
      }
      return;
    }
    if (action === "request-address") {
      state.requestedRecipientName = "";
      state.requestedRecipientPhone = "";
      openSheet("address-request");
      return;
    }
    if (action === "send-address-request") {
      const recipient = sheetContent.querySelector("[data-address-request-name]")?.value.trim();
      if (!recipient) {
        showToast("Add the receiving person or business");
        sheetContent.querySelector("[data-address-request-name]")?.focus();
        return;
      }
      const channel = button.dataset.addressChannel || "Share";
      const phone = sheetContent.querySelector("[data-address-request-phone]")?.value.trim() || "";
      const phoneDigits = phone.replace(/\D/g, "");
      if (channel === "WhatsApp" && (phoneDigits.length < 10 || phoneDigits.length > 13)) {
        showToast("Add the receiving contact for WhatsApp");
        sheetContent.querySelector("[data-address-request-phone]")?.focus();
        return;
      }
      state.requestedRecipientName = recipient;
      state.requestedRecipientPhone = phone;
      const message = addressRequestMessage();
      if (channel === "WhatsApp") {
        const whatsappNumber = phoneDigits.length === 10 ? `91${phoneDigits}` : phoneDigits;
        window.open(
          `https://wa.me/${whatsappNumber}?text=${encodeURIComponent(message)}`,
          "_blank",
          "noopener,noreferrer",
        );
        closeSheet();
        return;
      }
      if (channel === "MoolSocial") {
        closeSheet();
        showToast("Address request sent in MoolSocial");
        return;
      }
      if (navigator.share) {
        navigator.share({
          title: "MoolSocial delivery address",
          text: message,
        }).then(() => closeSheet()).catch((error) => {
          if (error?.name !== "AbortError") openSheet("share-apps");
        });
      } else {
        openSheet("share-apps");
      }
      return;
    }
    if (action === "enter-recipient-address") {
      state.requestedRecipientName =
        sheetContent.querySelector("[data-address-request-name]")?.value.trim() || "";
      state.requestedRecipientPhone =
        sheetContent.querySelector("[data-address-request-phone]")?.value.trim() || "";
      state.editingAddressId = null;
      state.addressDraftLabel = "Third party";
      state.addressDraft = {
        label: "Third party",
        recipient: state.requestedRecipientName,
        phone: state.requestedRecipientPhone,
      };
      openSheet("address-form");
      return;
    }
    if (action === "copy-address-request") {
      navigator.clipboard?.writeText(addressRequestMessage());
      closeSheet();
      showToast("Address request copied");
      return;
    }
    if (action === "email-address-request") {
      window.location.href =
        `mailto:?subject=${encodeURIComponent("MoolSocial delivery address")}&body=${encodeURIComponent(addressRequestMessage())}`;
      return;
    }
    if (action === "message-address-request") {
      window.location.href = `sms:?&body=${encodeURIComponent(addressRequestMessage())}`;
      return;
    }
    if (action === "change-confirm-address") {
      state.addressContext = button.dataset.addressContext || "personal";
      state.returnToAddressConfirmation = true;
      openSheet("location");
      return;
    }
    if (action === "confirm-address-and-order") {
      state.addressConfirmationKey = addressConfirmationSignature();
      closeSheet();
      completeOrder();
      return;
    }

    if (action === "assist-track-order") {
      closeSheet();
      openOrder(state.activeOrderId);
      return;
    }
    if (action === "assist-ask") {
      const input = sheetContent.querySelector("[data-assist-input]");
      answerAssist(input.value);
      return;
    }
    if (action === "assist-chat") {
      const chatPanel = sheetContent.querySelector("[data-assist-chat-panel]");
      chatPanel.hidden = false;
      chatPanel.querySelector("[data-assist-chat-input]").focus();
      return;
    }
    if (action === "assist-chat-send") {
      const input = sheetContent.querySelector("[data-assist-chat-input]");
      const messages = sheetContent.querySelector("[data-assist-chat-messages]");
      const message = input.value.trim();
      if (!message) {
        input.focus();
        return;
      }
      const bubble = document.createElement("p");
      bubble.className = "assist-message outgoing";
      bubble.textContent = message;
      messages.appendChild(bubble);
      input.value = "";
      input.focus();
      return;
    }
    if (action === "assist-call") {
      const response = sheetContent.querySelector("[data-assist-response]");
      const order = findOrder();
      response.hidden = false;
      response.querySelector("strong").textContent = "Connecting in MoolSocial";
      response.querySelector("span").textContent =
        `Your secure in-app support call for ${order.number} is starting.`;
      button.disabled = true;
      button.querySelector("strong").textContent = "Connecting…";
      setTimeout(() => {
        if (!document.body.contains(button)) return;
        button.disabled = false;
        button.querySelector("strong").textContent = "Call in app";
        response.querySelector("strong").textContent = "Support is ready";
        response.querySelector("span").textContent =
          "Stay in MoolSocial. Your support specialist can see this order when the call begins.";
      }, 700);
      return;
    }

    if (action === "past-prescriptions") {
      openSheet("past-prescriptions");
      return;
    }
    if (action === "new-prescription") {
      openSheet("prescription");
      return;
    }
    if (action === "use-saved-prescription") {
      state.selectedSavedPrescription =
        button.dataset.prescriptionName || "Saved prescription";
      setSavedPrescriptionCoverage(state.selectedSavedPrescription);
      state.prescriptionState = "review";
      setUrl({
        prescription: "review",
        medicine: state.prescriptionProduct || null,
      }, false);
      closeSheet();
      renderMedicine();
      openSheet("prescription-status");
      return;
    }
    if (action === "medicine-detail-add") {
      const productId = state.prescriptionProduct;
      closeSheet();
      addMedicineToCart(productId);
      return;
    }
    if (action === "medicine-detail-cart") {
      closeSheet();
      state.cartScope = availableCartScopes().length > 1 ? "all" : "medicine";
      state.cartReturnView = "medicine";
      showView("basket");
      return;
    }
    if (action === "medicine-detail-rx") {
      openSheet("past-prescriptions");
      return;
    }
    if (action === "medicine-detail-pharmacist") {
      openSheet("pharmacist");
      return;
    }
    if (action === "pharmacist-chat") {
      window.location.href = "23-chat-inbox-home.html?return=buy&conversation=pharmacist";
      return;
    }
    if (action === "pharmacist-call") {
      state.pharmacistState = "requested";
      closeSheet();
      renderMedicine();
      showToast("Pharmacist call requested · under 2 minutes");
      return;
    }
    if (action === "refill-prescription") {
      openSheet("past-prescriptions");
      return;
    }

    if (action === "apply-filter") {
      applyActiveFilter();
    }
    if (action === "choose-context") {
      closeSheet();
      setContext(button.dataset.value);
    }
    if (action === "open-saved") {
      state.context = button.dataset.saved === "business" ? "business" : "personal";
      if (state.context === "business") {
        state.carts.business = new Map([
          ["atta", { quantity: 2, packIndex: 0 }],
          ["oil", { quantity: 2, packIndex: 0 }],
        ]);
      } else {
        state.carts.personal = new Map([
          ["tomato", { quantity: 1, packIndex: 0 }],
          ["atta", { quantity: 1, packIndex: 0 }],
          ["rice", { quantity: 1, packIndex: 0 }],
        ]);
      }
      setUrl({
        context: state.context === "business" ? "business" : null,
        category: discovery().category === "all" ? null : discovery().category,
        sub: discovery().subcategory === "all" ? null : discovery().subcategory,
        q: discovery().search || null,
      }, false);
      renderContext();
      closeSheet();
      state.cartReturnView = state.context === "business" ? "wholesale" : "retail";
      showView("basket");
      showToast(state.context === "business" ? "Bulk restock opened" : "Weekly essentials opened in your cart");
    }
    if (action === "open-order") {
      closeSheet();
      setUrl({ received: null }, false);
      showView("tracking");
    }
    if (action === "open-delivered-order") {
      closeSheet();
      setUrl({ received: "1" }, false);
      showView("tracking");
    }
    if (action === "choose-slot") {
      state.deliveryChoices[state.context] = {
        title: button.dataset.slotTitle,
        detail: button.dataset.slotDetail,
        fee: Number(button.dataset.slotFee),
      };
      closeSheet();
      updateCartSurfaces();
      if (visibleView() === "basket") renderBasket();
      if (visibleView() === "checkout") renderCheckout();
      showToast("Delivery choice saved");
    }
    if (action === "scan-result") {
      closeSheet();
      openProduct("oil");
      showToast("Product found");
    }
    if (action === "prescription-added") {
      state.selectedSavedPrescription = "";
      setUploadedPrescriptionCoverage();
      state.prescriptionState = "review";
      setUrl({
        prescription: "review",
        medicine: state.prescriptionProduct || null,
      }, false);
      closeSheet();
      renderMedicine();
      openSheet("prescription-status");
    }
    if (action === "prescription-ready") {
      state.prescriptionState = "quoted";
      approvePrescriptionCoverage();
      setUrl({
        prescription: "quote",
        medicine: state.prescriptionProduct || null,
      }, false);
      closeSheet();
      renderMedicine();
      if (state.prescriptionProduct) {
        openSheet("medicine-detail");
      } else {
        openSheet("prescription-status");
      }
    }
    if (action === "prescription-view-medicines") {
      state.medicineCategory = "rx";
      closeSheet();
      setUrl({
        view: "medicine",
        med: "rx",
        sheet: null,
        prescription: null,
        medicine: null,
      }, false);
      renderMedicine();
      showView("medicine", { push: false });
      showToast("Verified medicines are ready to add");
      return;
    }
    if (action === "prescription-add-cart") {
      const approvedProduct = medicineProducts.find(
        (product) => product.id === state.prescriptionProduct,
      ) || prescriptionQuoteProduct;
      if (approvedProduct.prescriptionRequired) {
        state.rxApprovedProductIds.add(approvedProduct.id);
      }
      const key = medicineCartKey(approvedProduct.id);
      state.carts.personal.set(key, {
        kind: "medicine",
        quantity: 1,
        packIndex: 0,
      });
      state.cartScope = availableCartScopes().length > 1 ? "all" : "medicine";
      state.cartReturnView = "medicine";
      announceCartAddition(approvedProduct.title);
      closeSheet();
      renderMedicine();
    }
    if (action === "refill-created") {
      state.refillState = "active";
      closeSheet();
      renderMedicine();
      showToast("Refill reminder set · confirm before each order");
    }
  });

  noticeLayer.addEventListener("click", (event) => {
    const button = event.target.closest("[data-notice-action]");
    if (!button) return;
    const action = button.dataset.noticeAction;
    closeNotice();
    setUrl({ condition: null }, false);
    if (action === "change-pin") openSheet("location");
    if (action === "notify-area") showToast("We'll let you know when delivery opens here");
    if (action === "accept-price") {
      state.sellerChoices.personal.set("atta", 1);
      if (visibleView() === "basket") renderBasket();
      updateCartSurfaces();
      showToast(state.context === "business" ? "Bulk order updated with the new price" : "Cart updated with the new price");
    }
    if (action === "remove-atta") {
      state.carts.personal.delete("atta");
      renderBasket();
      updateCartSurfaces();
    }
    if (action === "remove-oil") {
      state.carts.personal.delete("oil");
      renderBasket();
      updateCartSurfaces();
    }
    if (action === "alternate-seller") {
      openProduct("oil");
      openSheet("compare");
    }
    if (action === "retry-payment") showToast("Payment ready to retry");
    if (action === "payment-method") {
      showView("basket");
      document.querySelector("[data-cart-payment-options] button")?.focus();
    }
    if (action === "retry-network") showToast("Page refreshed");
    if (action === "continue-offline") showToast("Saved Cart remains available");
    if (action === "keep-order") showToast("Updated delivery time saved");
    if (action === "order-help") {
      closeNotice();
      openSheet("order-assist");
    }
  });

  search.addEventListener("input", () => {
    discovery().search = search.value;
    if (discovery().search.trim() && (discovery().category !== "all" || discovery().subcategory !== "all")) {
      discovery().category = "all";
      discovery().subcategory = "all";
      renderCategories();
    }
    clearSearch.hidden = !discovery().search;
    setUrl({
      category: discovery().category === "all" ? null : discovery().category,
      sub: discovery().subcategory === "all" ? null : discovery().subcategory,
      q: discovery().search || null,
    }, false);
    renderProducts();
  });

  medicineSearch.addEventListener("input", () => {
    renderMedicine();
  });

  document.addEventListener("pointerdown", unlockScrollAudio, { capture: true, passive: true });
  document.addEventListener("touchmove", unlockScrollAudio, { capture: true, passive: true });
  document.addEventListener("wheel", unlockScrollAudio, { capture: true, passive: true });
  document.addEventListener("keydown", (event) => {
    if (["ArrowUp", "ArrowDown", "PageUp", "PageDown", "Home", "End", " "].includes(event.key)) {
      unlockScrollAudio();
    }
  }, { capture: true });
  document.addEventListener("scroll", handleScrollDetent, { capture: true, passive: true });

  [productGrid, productGridWide].forEach((grid) => {
    grid.addEventListener("keydown", (event) => {
      if ((event.key === "Enter" || event.key === " ") && event.target.matches("[data-product-id]")) {
        event.preventDefault();
        openProduct(event.target.dataset.productId);
      }
    });
  });

  contextSwipeSurface.addEventListener("pointerdown", (event) => {
    if (event.pointerType === "mouse" && event.button !== 0) return;
    if (visibleView() !== "catalogue" && visibleView() !== "product") return;
    if (event.target.closest("button, a, input, [role='button'], .category-rail, .pack-choice, .quantity-stepper")) return;
    contextSwipeStart = {
      x: event.clientX,
      y: event.clientY,
      pointerId: event.pointerId,
    };
  });

  contextSwipeSurface.addEventListener("pointerup", (event) => {
    if (!contextSwipeStart || contextSwipeStart.pointerId !== event.pointerId) return;
    const deltaX = event.clientX - contextSwipeStart.x;
    const deltaY = event.clientY - contextSwipeStart.y;
    contextSwipeStart = null;
    if (Math.abs(deltaX) < 34 || Math.abs(deltaX) <= Math.abs(deltaY) * 1.25) return;
    suppressContextClick = true;
    setContext(deltaX < 0 ? "business" : "personal");
    setTimeout(() => {
      suppressContextClick = false;
    }, 80);
  });

  contextSwipeSurface.addEventListener("pointercancel", () => {
    contextSwipeStart = null;
  });

  contextTabRail.addEventListener("keydown", (event) => {
    if (event.key !== "ArrowLeft" && event.key !== "ArrowRight") return;
    if (!event.target.matches("[data-context]")) return;
    event.preventDefault();
    const context = event.key === "ArrowRight" ? "business" : "personal";
    setContext(context);
    contextTabRail.querySelector(`[data-context="${context}"]`)?.focus();
  });

  sheetDragHandles.forEach((handle) => {
    handle.addEventListener("pointerdown", (event) => {
      if (sheetLayer.hidden || (event.pointerType === "mouse" && event.button !== 0)) return;
      sheetSwipeStart = {
        y: event.clientY,
        time: performance.now(),
        pointerId: event.pointerId,
      };
      sheet.classList.remove("is-settling", "is-dismissing");
      sheet.classList.add("is-dragging");
      handle.setPointerCapture?.(event.pointerId);
    });
    handle.addEventListener("pointermove", (event) => {
      if (!sheetSwipeStart || sheetSwipeStart.pointerId !== event.pointerId) return;
      const deltaY = Math.max(0, event.clientY - sheetSwipeStart.y);
      sheet.style.setProperty("--sheet-drag-y", `${deltaY}px`);
      if (deltaY > 4) event.preventDefault();
    });
    const finishSheetSwipe = (event) => {
      if (!sheetSwipeStart || sheetSwipeStart.pointerId !== event.pointerId) return;
      const deltaY = Math.max(0, event.clientY - sheetSwipeStart.y);
      const elapsed = Math.max(1, performance.now() - sheetSwipeStart.time);
      sheetSwipeStart = null;
      if (deltaY >= 64 || deltaY / elapsed >= 0.52) {
        hapticTick();
        closeSheet({ animate: true });
        return;
      }
      sheet.classList.remove("is-dragging");
      sheet.classList.add("is-settling");
      sheet.style.setProperty("--sheet-drag-y", "0px");
      setTimeout(() => {
        sheet.classList.remove("is-settling");
        sheet.style.removeProperty("--sheet-drag-y");
      }, 190);
    };
    handle.addEventListener("pointerup", finishSheetSwipe);
    handle.addEventListener("pointercancel", () => {
      sheetSwipeStart = null;
      sheet.classList.remove("is-dragging");
      sheet.classList.add("is-settling");
      sheet.style.setProperty("--sheet-drag-y", "0px");
    });
  });

  window.addEventListener("popstate", restoreFromUrl);
  window.addEventListener("resize", () => {
    window.requestAnimationFrame(() => {
      if (visibleView() === "medicine") {
        alignCategoryRail(medicineCategoryRail, medicineCatalogueResults);
      } else if (visibleView() === "catalogue") {
        alignCategoryRail(categoryRail, catalogueResults);
      }
    });
  });
  document.addEventListener("keydown", (event) => {
    if (event.key !== "Escape") return;
    if (!noticeLayer.hidden) closeNotice();
    else if (!sheetLayer.hidden) closeSheet();
  });

  restoreFromUrl();
})();
