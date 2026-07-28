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
    "breakfast-instant": ["Morning Basket", "Rajasthan Foods Distribution", "Verified distributor"],
    "packaged-foods": ["Family Supermart", "Jodhpur Packaged Foods Hub", "Verified distributor"],
    "snacks-confectionery": ["Snack Street", "Marwar Snacks Distribution", "Verified distributor"],
    beverages: ["Daily Drinks Store", "Rajasthan Beverage Supply", "Verified distributor"],
    "frozen-chilled": ["Fresh & Frozen", "Jodhpur Cold Supply", "Verified distributor"],
    "personal-care": ["Care Corner", "Marwar Care Distribution", "Verified distributor"],
    "beauty-grooming": ["Beauty Basket", "Rajasthan Beauty Supply", "Verified distributor"],
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
    filter: "",
    currentProduct: products[0],
    quantity: 1,
    selectedPack: 0,
    payment: "upi",
    sellerChoices: {
      personal: new Map(),
      business: new Map(),
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
      personal: new URLSearchParams(window.location.search).get("seed") === "1"
        ? new Map([
            ["tomato", { quantity: 1, packIndex: 0 }],
            ["atta", { quantity: 1, packIndex: 0 }],
          ])
        : new Map(),
      business: new URLSearchParams(window.location.search).get("seed") === "1"
        ? new Map([
            ["atta", { quantity: 2, packIndex: 0 }],
          ])
        : new Map(),
    },
  };

  const views = [...document.querySelectorAll("[data-view]")];
  const productGrid = document.querySelector("[data-product-grid]");
  const relatedProducts = document.querySelector("[data-related-products]");
  const relatedProductGrid = document.querySelector("[data-related-product-grid]");
  const relatedKicker = document.querySelector("[data-related-kicker]");
  const relatedTitle = document.querySelector("[data-related-title]");
  const emptyResults = document.querySelector("[data-empty-results]");
  const search = document.querySelector("[data-search]");
  const contextSwipeSurface = document.querySelector("[data-buy-stage]");
  const contextTabRail = document.querySelector("[data-mode-switch]");
  const categoryItems = document.querySelector("[data-category-items]");
  const catalogueScopeKicker = document.querySelector("[data-catalogue-scope-kicker]");
  const catalogueScopeTitle = document.querySelector("[data-catalogue-scope-title]");
  const catalogueScopeCount = document.querySelector("[data-catalogue-scope-count]");
  const subcategoryRow = document.querySelector("[data-subcategory-row]");
  const medicineSearch = document.querySelector("[data-medicine-search]");
  const medicineResults = document.querySelector("[data-medicine-results]");
  const clearSearch = document.querySelector("[data-action='clear-search']");
  const sheetLayer = document.querySelector("[data-sheet-layer]");
  const sheetTitle = document.querySelector("[data-sheet-title]");
  const sheetKicker = document.querySelector("[data-sheet-kicker]");
  const sheetContent = document.querySelector("[data-sheet-content]");
  const noticeLayer = document.querySelector("[data-notice-layer]");
  const toast = document.querySelector("[data-toast]");
  let toastTimer;
  let contextMotionTimer;
  let contextSwipeStart = null;
  let suppressContextClick = false;

  const query = () => new URLSearchParams(window.location.search);
  const discovery = () => state.discovery[state.context];
  const productCategory = (product) =>
    state.context === "business" ? product.businessCategory : product.category;
  const productSubcategory = (product) =>
    state.context === "business" ? product.businessSubcategory : product.subcategory;
  const availableCategories = () => categorySets[state.context];
  const availableSubcategories = (category = discovery().category) =>
    subcategorySets[state.context][category] || [];
  const isCategoryAvailable = (category) =>
    availableCategories().some((item) => item.id === category && !item.view);
  const isSubcategoryAvailable = (subcategory, category = discovery().category) =>
    subcategory === "all" || availableSubcategories(category).includes(subcategory);
  const hapticTick = () => {
    if (typeof navigator.vibrate === "function") navigator.vibrate(8);
  };

  const currentOffer = (product = state.currentProduct, packIndex = state.selectedPack) => {
    const offer = product[state.context];
    const selectedIndex = state.sellerChoices[state.context].get(product.id);
    const seller = Number.isInteger(selectedIndex) ? offer.sellers[selectedIndex] : null;
    const sellerNote = seller ? seller[2].split(" · ") : [];
    const selectedPack = offer.packs[packIndex] || offer.packs[0];
    const packPriceMatch = state.context === "personal" ? selectedPack[1].match(/₹([\d,]+(?:\.\d+)?)/) : null;
    const selectedPrice = seller
      ? seller[3]
      : packPriceMatch
        ? Number(packPriceMatch[1].replace(/,/g, ""))
        : offer.price;
    let selectedUnit = offer.unit;
    if (state.context === "personal" && packPriceMatch) {
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
    }
    return {
      ...offer,
      pack: selectedPack[0],
      unit: selectedUnit,
      seller: seller ? seller[1] : offer.seller,
      sellerType: seller ? sellerNote[0] : offer.sellerType,
      delivery: seller ? (sellerNote.slice(1).join(" · ") || offer.delivery) : offer.delivery,
      price: selectedPrice,
      badge: seller ? seller[4] : offer.badge,
    };
  };

  const minimumQuantity = (product = state.currentProduct, packIndex = state.selectedPack) => {
    if (state.context !== "business") return 1;
    const note = product.business.packs[packIndex]?.[1] || "";
    const match = note.match(/MOQ\s+(\d+)/i);
    return match ? Number(match[1]) : 1;
  };

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
      const active =
        (nav === "buy" && !["orders", "confirmed", "tracking"].includes(view)) ||
        (nav === "orders" && ["orders", "confirmed", "tracking"].includes(view));
      button.classList.toggle("active", active);
      if (active) button.setAttribute("aria-current", "page");
      else button.removeAttribute("aria-current");
    });
  };

  const showView = (name, { push = true } = {}) => {
    views.forEach((view) => view.classList.toggle("active", view.dataset.view === name));
    setDock(name);
    const nextUrl = { view: name === "catalogue" ? null : name };
    if (name !== "product") nextUrl.product = null;
    setUrl(nextUrl, push);
    const pill = document.querySelector("[data-action='basket'].basket-pill");
    pill.hidden = name !== "catalogue" || cartStats().count === 0;
    if (name === "basket") renderBasket();
    if (name === "checkout") renderCheckout();
    if (name === "confirmed") renderConfirmation();
    if (name === "tracking") renderTracking();
    document.querySelector("[data-buy-stage]")?.scrollTo?.({ top: 0 });
    window.scrollTo({ top: 0, behavior: "smooth" });
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
    const categoryRail = document.querySelector("[data-category-rail]");
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
      <article class="product-card" tabindex="0" role="button" data-product-id="${product.id}" aria-label="View ${product.title}">
        <span class="product-badge">${offer.badge}</span>
        ${productVisual(product)}
        <div class="product-card-body">
          <small>${product.brand}</small>
          <h2>${product.title}</h2>
          <p>${offer.pack} · ${offer.seller}</p>
          <div class="card-price-row ${cardQuantity > 0 ? "has-quantity" : ""}">
            <span class="card-price"><strong>${money(offer.price)}</strong><em>${offer.unit}</em></span>
            ${cartControl}
          </div>
          <span class="card-delivery">
            <svg viewBox="0 0 24 24" aria-hidden="true"><circle cx="12" cy="12" r="9"/><path d="M12 7v6l4 2"/></svg>
            ${offer.delivery}
          </span>
          ${wholesalePreview}
        </div>
      </article>`;
  };

  const renderRelatedProducts = (exactProducts, term) => {
    const currentDiscovery = discovery();
    const shouldShow =
      currentDiscovery.category !== "all" &&
      !term &&
      !state.filter &&
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
      .slice(0, 2);

    relatedProducts.hidden = candidates.length === 0;
    relatedKicker.textContent = state.context === "business" ? "For this order" : "Popular nearby";
    relatedTitle.textContent = state.context === "business" ? "Commonly ordered together" : "You may also need";
    relatedProductGrid.innerHTML = candidates.map(renderProductCard).join("");
  };

  const renderProducts = () => {
    const currentDiscovery = discovery();
    const term = currentDiscovery.search.trim().toLowerCase();
    const filtered = products.filter((product) => {
      const categoryMatch =
        currentDiscovery.category === "all" ||
        productCategory(product) === currentDiscovery.category;
      const subcategoryMatch =
        currentDiscovery.subcategory === "all" ||
        productSubcategory(product) === currentDiscovery.subcategory;
      const termMatch = !term || productSearchText(product).includes(term);
      const filterMatch =
        !state.filter ||
        (state.filter === "fast" && /minute|today/i.test(product[state.context].delivery)) ||
        (state.filter === "lowest" && /lowest|best/i.test(product[state.context].badge)) ||
        (state.filter === "manufacturer" && /manufacturer/i.test(product[state.context].sellerType));
      return categoryMatch && subcategoryMatch && termMatch && filterMatch;
    });

    renderCatalogueScope(filtered.length);
    productGrid.innerHTML = filtered.map(renderProductCard).join("");

    emptyResults.hidden = filtered.length > 0;
    productGrid.hidden = filtered.length === 0;
    renderRelatedProducts(filtered, term);
  };

  const renderContext = () => {
    document.querySelectorAll("[data-context]").forEach((button) => {
      const active = button.dataset.context === state.context;
      button.classList.toggle("active", active);
      button.setAttribute("aria-selected", String(active));
    });

    document.querySelector("[data-workspace-strip]").hidden = state.context !== "business";
    renderLocation();
    document.querySelector("[data-promise-kicker]").textContent =
      state.context === "business" ? "Verified bulk suppliers" : "Nearby sellers";
    document.querySelector("[data-promise-title]").textContent =
      state.context === "business" ? "Competitive bulk prices" : "Essentials from 12 minutes";
    document.querySelector("[data-promise-note]").textContent =
      state.context === "business" ? "MOQ, tax and freight shown" : "Final delivered prices shown";
    document.querySelector("[data-catalogue-kicker]").textContent =
      state.context === "business" ? "Wholesale packs · business prices" : "Retail packs";
    document.querySelector("[data-catalogue-title]").textContent =
      state.context === "business" ? "Wholesale prices" : "Recommended near you";
    document.querySelector("[data-basket-pill-label]").textContent =
      state.context === "business" ? "Bulk order" : "Basket";
    document.querySelector("[data-basket-pill-copy]").textContent =
      state.context === "business" ? "Review bulk order" : "View basket";
    document.querySelector("[data-action='saved']").setAttribute(
      "aria-label",
      state.context === "business" ? "Saved bulk orders" : "Saved baskets",
    );
    search.value = discovery().search;
    search.placeholder = state.context === "business"
      ? "Search wholesale products, packs or suppliers"
      : "Search retail products or brands";
    clearSearch.hidden = !discovery().search;
    renderCategories();
    state.selectedPack = 0;
    state.quantity = minimumQuantity(state.currentProduct, 0);
    renderProducts();
    updateCartSurfaces();
    if (visibleView() === "product") renderProduct();
    if (visibleView() === "basket") renderBasket();
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
    const offer = currentOffer();
    document.querySelector("[data-product-art]").innerHTML = art[product.visual];
    document.querySelector("[data-product-context]").textContent =
      state.context === "business" ? "Wholesale" : "Retail";
    document.querySelector("[data-product-brand]").textContent = product.brand;
    document.querySelector("[data-product-title]").textContent = product.title;
    document.querySelector("[data-product-pack]").textContent = offer.pack;
    document.querySelector("[data-product-stock]").textContent = offer.stock;
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

    document.querySelector("[data-pack-choice]").innerHTML = offer.packs
      .map(
        ([name, note], index) => `
          <button class="pack-option ${state.selectedPack === index ? "active" : ""}" type="button" role="radio"
            aria-checked="${state.selectedPack === index}" data-pack-index="${index}">
            <strong>${name}</strong><span>${note}</span>
          </button>`,
      )
      .join("");

    document.querySelector("[data-offer-facts]").innerHTML = [
      ["Delivery", offer.delivery],
      ["Service area", offer.location],
      [state.context === "business" ? "Minimum order" : "Availability", state.context === "business" ? offer.packs[state.selectedPack][1] : offer.stock],
      ["Returns", offer.returnTerm],
    ]
      .map(([label, value]) => `<span class="offer-fact"><small>${label}</small><strong>${value}</strong></span>`)
      .join("");

    const businessTerms = document.querySelector("[data-business-terms]");
    businessTerms.hidden = state.context !== "business";
    if (state.context === "business") {
      document.querySelector("[data-price-breaks]").innerHTML = offer.breaks
        .map(
          ([range, price], index) =>
            `<span class="price-break ${index === 0 ? "active" : ""}"><small>${range}</small><strong>${price}</strong></span>`,
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
    state.currentProduct = product;
    state.selectedPack = 0;
    state.quantity = minimumQuantity(product, 0);
    setUrl({ product: id }, push);
    renderProduct();
    showView("product", { push: false });
  };

  const updateQuantity = () => {
    const offer = currentOffer();
    const unitName = state.context === "business" ? (state.quantity === 1 ? "case" : "cases") : (state.quantity === 1 ? "pack" : "packs");
    document.querySelector("[data-quantity]").textContent = String(state.quantity);
    document.querySelector("[data-quantity-label]").textContent = `${state.quantity} ${unitName}`;
    document.querySelector("[data-add-detail-price]").textContent = money(offer.price * state.quantity);
    document.querySelector("[data-add-detail-label]").textContent =
      state.context === "business" ? "Add to bulk order" : "Add to basket";
  };

  const cart = () => state.carts[state.context];

  const cartStats = () => {
    let count = 0;
    let subtotal = 0;
    cart().forEach((item, id) => {
      const product = products.find((item) => item.id === id);
      if (!product) return;
      const normalized = typeof item === "number" ? { quantity: item, packIndex: 0 } : item;
      count += normalized.quantity;
      subtotal += currentOffer(product, normalized.packIndex).price * normalized.quantity;
    });
    const selectedFee = state.deliveryChoices[state.context].fee;
    const defaultDelivery = state.context === "business"
      ? (subtotal >= 5000 ? 0 : 180)
      : (subtotal >= 499 ? 0 : 24);
    const delivery = count === 0 ? 0 : selectedFee === null ? defaultDelivery : selectedFee;
    return { count, subtotal, delivery, total: subtotal + delivery };
  };

  const updateCartSurfaces = () => {
    const stats = cartStats();
    const pill = document.querySelector(".basket-pill");
    pill.hidden = stats.count === 0 || visibleView() !== "catalogue";
    document.querySelector("[data-basket-pill-count]").textContent = String(stats.count);
    document.querySelector("[data-basket-pill-total]").textContent = money(stats.total);
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
    updateCartSurfaces();
    showToast(`${product.title} added to ${state.context === "business" ? "your bulk order" : "your basket"}`);
  };

  const changeCartQuantity = (id, delta) => {
    const product = products.find((item) => item.id === id);
    const existing = cart().get(id);
    if (!product || !existing) return;
    const normalized = typeof existing === "number"
      ? { quantity: existing, packIndex: 0 }
      : existing;
    const minimum = minimumQuantity(product, normalized.packIndex);
    const nextQuantity = normalized.quantity + delta;
    if (nextQuantity < minimum) cart().delete(id);
    else cart().set(id, { ...normalized, quantity: nextQuantity });
    updateCartSurfaces();
    renderProducts();
    hapticTick();
  };

  const renderBasket = () => {
    const items = [...cart().entries()];
    const stats = cartStats();
    const business = state.context === "business";
    document.querySelector("[data-basket-title]").textContent = business ? "Bulk order" : "Your basket";
    document.querySelector("[data-empty-order-title]").textContent =
      business ? "Build your bulk order" : "Your basket is ready when you are";
    document.querySelector("[data-empty-order-copy]").textContent =
      business
        ? "Add wholesale packs to review MOQ, tax, freight and purchase-order terms."
        : "Add products to see final prices and delivery choices.";
    document.querySelector("[data-basket-context]").innerHTML =
      business
        ? `<span>SB</span><span><small>Bulk order</small><strong>Shree Balaji Retail</strong></span>`
        : `<span>DC</span><span><small>Basket</small><strong>Dharmendra</strong></span>`;

    document.querySelector("[data-basket-items]").innerHTML = items
      .map(([id, item]) => {
        const product = products.find((item) => item.id === id);
        const normalized = typeof item === "number" ? { quantity: item, packIndex: 0 } : item;
        const offer = currentOffer(product, normalized.packIndex);
        return `
          <article class="basket-item">
            <span class="basket-item-art">${art[product.visual]}</span>
            <span class="basket-item-copy">
              <strong>${product.title}</strong>
              <span>${offer.pack} · Qty ${normalized.quantity}</span>
              <em>${offer.seller}</em>
            </span>
            <span class="basket-item-end">
              <strong>${money(offer.price * normalized.quantity)}</strong>
              <button type="button" data-remove="${id}">Remove</button>
            </span>
          </article>`;
      })
      .join("");

    document.querySelector("[data-basket-empty]").hidden = items.length > 0;
    document.querySelector("[data-basket-items]").hidden = items.length === 0;
    document.querySelector("[data-basket-summary]").hidden = items.length === 0;
    document.querySelector(".basket-continue").hidden = items.length === 0;
    document.querySelector("[data-basket-subtotal]").textContent = money(stats.subtotal);
    document.querySelector("[data-basket-delivery]").textContent = stats.delivery ? money(stats.delivery) : "Included";
    document.querySelector("[data-basket-total]").textContent = money(stats.total);
    document.querySelector("[data-checkout-total]").textContent = money(stats.total);
    document.querySelector("[data-delivery-label]").textContent =
      state.context === "business" ? "Freight" : "Delivery";
    document.querySelector("[data-total-label]").textContent =
      state.context === "business" ? "Landed total" : "Total";
    document.querySelector("[data-total-note]").textContent =
      state.context === "business" ? "Tax and freight shown for every item" : "Includes all charges shown above";
    document.querySelector("[data-checkout-label]").textContent =
      state.context === "business" ? "Review purchase order" : "Choose delivery and payment";
  };

  const renderCheckout = () => {
    const stats = cartStats();
    const business = state.context === "business";
    const location = state.locations[state.context];
    const deliveryChoice = state.deliveryChoices[state.context];
    document.querySelector("[data-checkout-title]").textContent = business ? "Review purchase order" : "Review order";
    document.querySelector("[data-address-label]").textContent = business ? "Deliver to business" : "Deliver to";
    document.querySelector("[data-address-value]").textContent = location.address;
    document.querySelector("[data-address-detail]").textContent = location.detail;
    document.querySelector("[data-slot-label]").textContent = business ? "Business delivery" : "Delivery";
    document.querySelector("[data-slot-value]").textContent = deliveryChoice.title;
    document.querySelector("[data-slot-detail]").textContent = deliveryChoice.detail;
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

    const options = business
      ? [
          ["bank", "BANK", "Bank transfer", "Payment due before dispatch"],
          ["upi", "UPI", "UPI", "Pay when the purchase order is accepted"],
          ["credit", "7D", "7-day credit", "Approved for this workspace"],
        ]
      : [
          ["upi", "UPI", "UPI", "Fast and secure"],
          ["card", "CARD", "Debit or credit card", "Visa, Mastercard and RuPay"],
          ["cod", "CASH", "Pay on delivery", "Cash or UPI at delivery"],
        ];
    if (!options.some(([id]) => id === state.payment)) state.payment = options[0][0];
    document.querySelector("[data-payment-options]").innerHTML = options
      .map(
        ([id, icon, title, note]) => `
          <button class="payment-option ${state.payment === id ? "active" : ""}" type="button" role="radio"
            aria-checked="${state.payment === id}" data-payment="${id}">
            <span>${icon}</span><span><strong>${title}</strong><small>${note}</small></span><i class="payment-radio"></i>
          </button>`,
      )
      .join("");
  };

  const renderConfirmation = () => {
    const business = state.context === "business";
    const deliveryChoice = state.deliveryChoices[state.context];
    document.querySelector("[data-confirmation-kicker]").textContent = business ? "Purchase order received" : "Thank you";
    document.querySelector("[data-confirmation-title]").textContent = business ? "Purchase order placed" : "Order confirmed";
    document.querySelector("[data-confirmation-note]").textContent = business
      ? `Suppliers will confirm stock and dispatch commitments for ${deliveryChoice.title.toLowerCase()}. You can follow every update from your workspace.`
      : `Your order is scheduled for ${deliveryChoice.title.toLowerCase()}.`;
    document.querySelector("[data-confirmation-number-label]").textContent = business ? "Purchase order" : "Order";
    document.querySelector("[data-confirmation-number]").textContent = business ? "PO-240782" : "MS-240782";
    document.querySelector("[data-track-label]").textContent = business ? "Open purchase order" : "Track order";
  };

  const renderTracking = () => {
    const business = state.context === "business";
    const deliveryChoice = state.deliveryChoices[state.context];
    document.querySelector("[data-tracking-kicker]").textContent = business ? "Supplier confirmation" : "Preparing your order";
    document.querySelector("[data-tracking-title]").textContent = business ? "Purchase order in progress" : "Order is on schedule";
    document.querySelector("[data-tracking-note]").textContent = business
      ? `${deliveryChoice.title} · supplier commitments and dispatch updates will appear here.`
      : `${deliveryChoice.title} · delivery updates will appear here as your order moves.`;
    document.querySelector("[data-tracking-number]").textContent = business ? "PO-240782" : "MS-240782";
    document.querySelector("[data-tracking-step-one]").textContent = business ? "Purchase order placed" : "Order confirmed";
    document.querySelector("[data-tracking-step-one-note]").textContent = business ? "Terms and quantities recorded" : "Payment and stock checked";
    document.querySelector("[data-tracking-step-two]").textContent = business ? "Supplier confirmation" : "Preparing your order";
    document.querySelector("[data-tracking-step-two-note]").textContent = business ? "One supplier has confirmed stock" : "Seller is packing your items";
    document.querySelector("[data-tracking-step-three]").textContent = business ? "Dispatch" : "Out for delivery";
    document.querySelector("[data-tracking-step-three-note]").textContent = business ? "Shipment tracking starts after pickup" : "Live tracking starts after pickup";
    document.querySelector("[data-tracking-update-title]").textContent = business ? "1 of 2 suppliers confirmed" : "Seller confirmed your order";
    document.querySelector("[data-tracking-update-note]").textContent = business
      ? "Marwar Foods Distribution confirmed the ordered quantity. The second supplier is due to respond by 10:30 am."
      : "All items are available and preparation has started.";
  };

  const openSheet = (type) => {
    sheetKicker.textContent = "Choose";
    sheetTitle.textContent = "Options";
    let html = "";

    if (type === "filters") {
      sheetKicker.textContent = state.context === "business" ? "Wholesale" : "Retail";
      sheetTitle.textContent = "Filter products";
      const filterGroups = [
        ["Delivery", [["fast", state.context === "business" ? "Next-day delivery" : "Fast delivery"], ["", "Any time"]]],
        ["Price", [["lowest", state.context === "business" ? "Best landed cost" : "Lowest delivered price"], ["", "All prices"]]],
      ];
      if (state.context === "business") {
        filterGroups.push(["Seller", [["manufacturer", "Manufacturer offers"], ["", "All verified sellers"]]]);
      }
      html = filterGroups
        .map(
          ([label, choices]) => `
            <section class="filter-section"><strong>${label}</strong><div class="filter-chips">
              ${choices
                .map(
                  ([value, text]) =>
                    `<button class="filter-chip ${state.filter === value ? "active" : ""}" type="button" data-filter-value="${value}">${text}</button>`,
                )
                .join("")}
            </div></section>`,
        )
        .join("");
      html += `<button class="sheet-primary" type="button" data-sheet-action="apply-filter">Show products</button>`;
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
      const offer = currentOffer();
      sheetKicker.textContent = state.currentProduct.title;
      sheetTitle.textContent = state.context === "business" ? "Compare landed offers" : "Compare sellers";
      html = offer.sellers
        .map(
          ([avatar, seller, note, price, reason], index) => `
            <button class="seller-option" type="button" data-seller-index="${index}">
              <span>${avatar}</span><span><strong>${seller}</strong><small>${note}</small></span>
              <span><strong>${money(price)}</strong><small>${reason}</small></span>
            </button>`,
        )
        .join("");
    }

    if (type === "location") {
      sheetKicker.textContent = state.context === "business" ? "Bulk service area" : "Delivery area";
      sheetTitle.textContent = "Check PIN code";
      html = `
        <div class="pin-entry">
          <input type="text" inputmode="numeric" maxlength="6" value="342003" aria-label="PIN code" data-pin-input />
          <button type="button" data-sheet-action="check-pin">Check</button>
        </div>
        <button class="sheet-option active" type="button" data-sheet-action="use-pin" data-pin="342003">
          <span><strong>Sardarpura, Jodhpur</strong><small>Home and business delivery available</small></span><b>342003</b>
        </button>
        <button class="sheet-option" type="button" data-sheet-action="use-pin" data-pin="342008">
          <span><strong>Pal, Jodhpur</strong><small>Home and business delivery available</small></span><b>342008</b>
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
      sheetKicker.textContent = state.context === "business" ? "Saved bulk orders" : "Saved baskets";
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
          <span><strong>Order MS-240782</strong><small>Preparing · delivery updates available</small></span><b>Track</b>
        </button>
        <button class="saved-option" type="button" data-sheet-action="open-saved" data-saved="${state.context}">
          <span><strong>${state.context === "business" ? "Store restock" : "Weekly essentials"}</strong><small>Delivered · order these items again</small></span><b>Reorder</b>
        </button>`;
    }

    if (type === "delivery-times") {
      sheetKicker.textContent = state.context === "business" ? "Business delivery" : "Home delivery";
      sheetTitle.textContent = "Available delivery times";
      html = state.context === "business"
        ? `
          <button class="slot-option active" type="button" data-sheet-action="choose-slot" data-slot-title="Tomorrow · 10:00 am–2:00 pm" data-slot-detail="All current suppliers available" data-slot-fee="0"><span><strong>Tomorrow · 10:00 am–2:00 pm</strong><small>All current suppliers available</small></span><b>Included</b></button>
          <button class="slot-option" type="button" data-sheet-action="choose-slot" data-slot-title="Tomorrow · 4:00–7:00 pm" data-slot-detail="Two supplier deliveries" data-slot-fee="90"><span><strong>Tomorrow · 4:00–7:00 pm</strong><small>Two supplier deliveries</small></span><b>₹90</b></button>`
        : `
          <button class="slot-option active" type="button" data-sheet-action="choose-slot" data-slot-title="12-minute delivery" data-slot-detail="Selected nearby products" data-slot-fee="24"><span><strong>12-minute delivery</strong><small>Selected nearby products</small></span><b>₹24</b></button>
          <button class="slot-option" type="button" data-sheet-action="choose-slot" data-slot-title="Today · 7:00–7:30 pm" data-slot-detail="All products together" data-slot-fee="0"><span><strong>Today · 7:00–7:30 pm</strong><small>All products together</small></span><b>Included</b></button>`;
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

    if (type === "prescription") {
      sheetKicker.textContent = "Prescription";
      sheetTitle.textContent = "Add your prescription";
      html = `
        <button class="sheet-option" type="button" data-sheet-action="prescription-added"><span><strong>Take a photo</strong><small>Use your phone camera</small></span><b>Camera</b></button>
        <button class="sheet-option" type="button" data-sheet-action="prescription-added"><span><strong>Choose from phone</strong><small>Photo or PDF</small></span><b>Choose</b></button>`;
    }

    if (type === "delivery-slot") {
      sheetKicker.textContent = "Choose";
      sheetTitle.textContent = state.context === "business" ? "Business delivery" : "Delivery time";
      html = state.context === "business"
        ? `
          <button class="slot-option active" type="button" data-sheet-action="choose-slot" data-slot-title="Tomorrow · 10:00 am–2:00 pm" data-slot-detail="Supplier commitments included" data-slot-fee="0"><span><strong>Tomorrow · 10:00 am–2:00 pm</strong><small>Supplier commitments included</small></span><b>Selected</b></button>
          <button class="slot-option" type="button" data-sheet-action="choose-slot" data-slot-title="Within two days" data-slot-detail="Lower freight option" data-slot-fee="0"><span><strong>Within two days</strong><small>Lower freight option</small></span><b>Save ₹90</b></button>`
        : `
          <button class="slot-option active" type="button" data-sheet-action="choose-slot" data-slot-title="Today · 7:00–7:30 pm" data-slot-detail="All products together" data-slot-fee="0"><span><strong>Today · 7:00–7:30 pm</strong><small>All products together</small></span><b>Selected</b></button>
          <button class="slot-option" type="button" data-sheet-action="choose-slot" data-slot-title="Deliver as soon as ready" data-slot-detail="May arrive in separate deliveries" data-slot-fee="24"><span><strong>Deliver as soon as ready</strong><small>May arrive in separate deliveries</small></span><b>₹24</b></button>`;
    }

    sheetContent.innerHTML = html;
    sheetLayer.hidden = false;
    document.body.style.overflow = "hidden";
    setTimeout(() => sheetLayer.querySelector("button, input")?.focus(), 0);
  };

  const closeSheet = () => {
    sheetLayer.hidden = true;
    document.body.style.overflow = "";
    if (query().has("sheet")) setUrl({ sheet: null }, false);
    setDock(visibleView());
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
        kicker: state.context === "business" ? "Bulk order update" : "Basket update",
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
          : "No verified seller can currently deliver this basket to PIN code 110001. Your basket is still saved.",
        actions: [
          { label: "Change PIN code", action: "change-pin" },
          { label: "Notify me", action: "notify-area" },
        ],
      });
    }
  };

  const restoreFromUrl = () => {
    const params = query();
    state.context = params.get("context") === "business" ? "business" : "personal";
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
    const view = ["product", "medicine", "basket", "checkout", "confirmed", "tracking"].includes(params.get("view"))
      ? params.get("view")
      : "catalogue";
    if (view === "product") renderProduct();
    showView(view, { push: false });
    if (params.get("sheet") === "orders") {
      openSheet("orders");
      setDock("orders");
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
      changeCartQuantity(button.dataset.cardIncrease, 1);
      return;
    }

    if (button.dataset.cardDecrease) {
      event.stopPropagation();
      changeCartQuantity(button.dataset.cardDecrease, -1);
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
      cart().delete(button.dataset.remove);
      renderBasket();
      updateCartSurfaces();
      return;
    }

    if (button.dataset.payment) {
      state.payment = button.dataset.payment;
      renderCheckout();
      return;
    }

    if (button.dataset.nav) {
      if (button.dataset.nav === "buy") showView("catalogue");
      if (button.dataset.nav === "orders") {
        setUrl({ sheet: "orders" });
        openSheet("orders");
        setDock("orders");
      }
      return;
    }

    const action = button.dataset.action;
    if (!action) return;

    if (action === "saved") openSheet("saved");
    if (action === "account") openSheet("account");
    if (action === "location" || action === "change-address") openSheet("location");
    if (action === "filters") openSheet("filters");
    if (action === "category-more" || action === "category-less") {
      state.categoryRailExpanded[state.context] = action === "category-more";
      renderCategories();
      hapticTick();
    }
    if (action === "delivery-times") openSheet("delivery-times");
    if (action === "scan") openSheet("scan");
    if (action === "compare") openSheet("compare");
    if (action === "upload-prescription") openSheet("prescription");
    if (action === "delivery-slot") openSheet("delivery-slot");
    if (action === "close-sheet") closeSheet();
    if (action === "clear-search" || action === "reset-search") {
      discovery().search = "";
      search.value = "";
      clearSearch.hidden = true;
      setUrl({ q: null }, false);
      renderProducts();
      search.focus();
    }
    if (action === "clear-filter") {
      state.filter = "";
      document.querySelector("[data-active-filter-row]").hidden = true;
      renderProducts();
    }
    if (action === "catalogue") showView("catalogue");
    if (action === "back") window.history.length > 1 ? window.history.back() : showView("catalogue");
    if (action === "basket") showView("basket");
    if (action === "checkout") {
      if (cartStats().count === 0) showToast("Add a product before checkout");
      else showView("checkout");
    }
    if (action === "increase") {
      state.quantity += 1;
      updateQuantity();
    }
    if (action === "decrease") {
      state.quantity = Math.max(minimumQuantity(), state.quantity - 1);
      updateQuantity();
    }
    if (action === "add-detail") addToCart(state.currentProduct.id, state.quantity, state.selectedPack);
    if (action === "save-product") showToast(`${state.currentProduct.title} saved`);
    if (action === "clear-basket") {
      cart().clear();
      renderBasket();
      updateCartSurfaces();
    }
    if (action === "pharmacist") {
      window.location.href = "23-chat-inbox-home.html?return=buy&conversation=pharmacist";
    }
    if (action === "start-refill") showToast("Monthly refill started");
    if (action === "confirm-order") {
      if (state.context === "business" && !document.querySelector("[data-po-consent]").checked) {
        showToast("Confirm the purchase order terms to continue");
        document.querySelector("[data-po-consent]").focus();
        return;
      }
      showView("confirmed");
    }
    if (action === "track-order") showView("tracking");
    if (action === "confirmation") showView("confirmed");
    if (action === "continue-shopping") {
      cart().clear();
      updateCartSurfaces();
      renderProducts();
      showView("catalogue");
    }
  });

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

    if (button.dataset.filterValue !== undefined) {
      state.filter = button.dataset.filterValue;
      sheetContent.querySelectorAll("[data-filter-value]").forEach((item) => item.classList.toggle("active", item === button));
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

    const action = button.dataset.sheetAction;
    if (!action) return;

    if (action === "apply-filter") {
      const row = document.querySelector("[data-active-filter-row]");
      const labels = {
        fast: state.context === "business" ? "Next-day delivery" : "Fast delivery",
        lowest: state.context === "business" ? "Best landed cost" : "Lowest delivered price",
        manufacturer: "Manufacturer offers",
      };
      row.hidden = !state.filter;
      document.querySelector("[data-active-filter]").textContent = labels[state.filter] || "";
      closeSheet();
      renderProducts();
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
      showView("basket");
      showToast(state.context === "business" ? "Bulk restock opened" : "Weekly essentials basket opened");
    }
    if (action === "open-order") {
      closeSheet();
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
      closeSheet();
      showToast("Prescription added securely");
    }
    if (action === "use-pin") {
      const pal = button.dataset.pin === "342008";
      state.locations[state.context] = {
        label: pal ? "Pal · 342008" : "Sardarpura · 342003",
        address: state.context === "business"
          ? "Shree Balaji Retail"
          : pal ? "Home · Pal" : "Home · Sardarpura",
        detail: pal
          ? "Pal, Jodhpur, Rajasthan 342008"
          : "Jodhpur, Rajasthan 342003",
      };
      renderLocation();
      if (visibleView() === "checkout") renderCheckout();
      closeSheet();
      showToast("Delivery area updated");
    }
    if (action === "check-pin") {
      const pin = sheetContent.querySelector("[data-pin-input]")?.value.trim();
      if (["342003", "342008", "342001", "342011"].includes(pin)) {
        state.locations[state.context] = {
          label: `Jodhpur · ${pin}`,
          address: state.context === "business" ? "Shree Balaji Retail" : "Home · Jodhpur",
          detail: `Jodhpur, Rajasthan ${pin}`,
        };
        renderLocation();
        if (visibleView() === "checkout") renderCheckout();
        closeSheet();
        showToast("Delivery is available");
      } else {
        closeSheet();
        showCondition("unavailable");
      }
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
      showToast(state.context === "business" ? "Bulk order updated with the new price" : "Basket updated with the new price");
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
    const term = medicineSearch.value.trim().toLowerCase();
    const products = [
      ["Digital thermometer", "Health device", "From ₹149"],
      ["ORS hydration salts", "Wellness", "From ₹24"],
      ["Adhesive bandages", "First-aid care", "From ₹45"],
      ["Steam inhaler", "Home health", "From ₹399"],
    ].filter(([title, category]) => !term || `${title} ${category}`.toLowerCase().includes(term));
    medicineResults.hidden = !term;
    if (!term) {
      medicineResults.innerHTML = "";
      return;
    }
    medicineResults.innerHTML = products.length
      ? products
          .map(
            ([title, category, price]) => `
              <article>
                <span aria-hidden="true">+</span>
                <span><strong>${title}</strong><small>${category} · availability confirmed by a verified pharmacy</small></span>
                <b>${price}</b>
              </article>`,
          )
          .join("")
      : `<p>No matching health products found. Try another name or ask a pharmacist.</p>`;
  });

  productGrid.addEventListener("keydown", (event) => {
    if ((event.key === "Enter" || event.key === " ") && event.target.matches("[data-product-id]")) {
      event.preventDefault();
      openProduct(event.target.dataset.productId);
    }
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

  window.addEventListener("popstate", restoreFromUrl);
  document.addEventListener("keydown", (event) => {
    if (event.key !== "Escape") return;
    if (!noticeLayer.hidden) closeNotice();
    else if (!sheetLayer.hidden) closeSheet();
  });

  restoreFromUrl();
})();
