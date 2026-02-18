export interface MarketplaceItem {
  id: string;
  title: string;
  price: number;
  description: string;
  category: string;
  condition: string;
  image: string;
  seller: string;
  createdAt: string;
  location: string;
}

export interface LostFoundItem {
  id: string;
  title: string;
  description: string;
  category: string;
  type: 'lost' | 'found';
  image: string;
  poster: string;
  createdAt: string;
  location: string;
  status: 'active' | 'resolved';
}

export const marketplaceItems: MarketplaceItem[] = [
  {
    id: '1',
    title: 'Chemistry Textbook - 11th Edition',
    price: 45,
    description: 'Barely used chemistry textbook. Perfect condition with no highlighting or notes.',
    category: 'Textbooks',
    condition: 'Like New',
    image: 'https://images.unsplash.com/photo-1589998059171-988d887df646?w=400',
    seller: 'Sarah M.',
    createdAt: '2026-02-10',
    location: 'Blanton Hall'
  },
  {
    id: '2',
    title: 'Mini Fridge - Perfect for Dorms',
    price: 80,
    description: 'Compact mini fridge, great for dorm rooms. Works perfectly, very quiet.',
    category: 'Furniture',
    condition: 'Good',
    image: 'https://images.unsplash.com/photo-1571175443880-49e1d25b2bc5?w=400',
    seller: 'Mike T.',
    createdAt: '2026-02-09',
    location: 'Freeman Hall'
  },
  {
    id: '3',
    title: 'Scientific Calculator TI-84',
    price: 60,
    description: 'TI-84 Plus graphing calculator. Great for math and science courses.',
    category: 'Electronics',
    condition: 'Good',
    image: 'https://images.unsplash.com/photo-1611367840531-628f328d9a49?w=400',
    seller: 'Jessica L.',
    createdAt: '2026-02-08',
    location: 'Student Center'
  },
  {
    id: '4',
    title: 'Desk Lamp with USB Port',
    price: 15,
    description: 'LED desk lamp with adjustable brightness and USB charging port.',
    category: 'Furniture',
    condition: 'Like New',
    image: 'https://images.unsplash.com/photo-1507473885765-e6ed057f782c?w=400',
    seller: 'Alex K.',
    createdAt: '2026-02-07',
    location: 'Bohn Hall'
  },
  {
    id: '5',
    title: 'MacBook Pro Charger',
    price: 30,
    description: 'Original Apple 61W USB-C power adapter. Compatible with MacBook Pro.',
    category: 'Electronics',
    condition: 'Good',
    image: 'https://images.unsplash.com/photo-1591290619762-d06df1a8a8b0?w=400',
    seller: 'David R.',
    createdAt: '2026-02-06',
    location: 'Library'
  },
  {
    id: '6',
    title: 'Biology Lab Coat',
    price: 12,
    description: 'White lab coat, size medium. Lightly used for one semester.',
    category: 'Other',
    condition: 'Good',
    image: 'https://images.unsplash.com/photo-1576671081837-49000212a370?w=400',
    seller: 'Emma W.',
    createdAt: '2026-02-05',
    location: 'Richardson Hall'
  }
];

export const lostFoundItems: LostFoundItem[] = [
  {
    id: 'lf1',
    title: 'Black Backpack with Laptop',
    description: 'Lost black Jansport backpack containing a laptop and notebooks. Left in the library on the 3rd floor.',
    category: 'Bags',
    type: 'lost',
    image: 'https://images.unsplash.com/photo-1553062407-98eeb64c6a62?w=400',
    poster: 'James P.',
    createdAt: '2026-02-11',
    location: 'Sprague Library - 3rd Floor',
    status: 'active'
  },
  {
    id: 'lf2',
    title: 'Found: AirPods in Case',
    description: 'Found AirPods with charging case near the dining hall entrance.',
    category: 'Electronics',
    type: 'found',
    image: 'https://images.unsplash.com/photo-1606841837239-c5a1a4a07af7?w=400',
    poster: 'Maria G.',
    createdAt: '2026-02-10',
    location: 'Student Center Dining Hall',
    status: 'active'
  },
  {
    id: 'lf3',
    title: 'Lost Student ID Card',
    description: 'Lost my student ID card somewhere between Dickson Hall and the parking lot.',
    category: 'ID/Cards',
    type: 'lost',
    image: 'https://images.unsplash.com/photo-1585155770958-eeb77df44de8?w=400',
    poster: 'Kevin S.',
    createdAt: '2026-02-09',
    location: 'Between Dickson Hall & Lot 60',
    status: 'active'
  },
  {
    id: 'lf4',
    title: 'Found: Red Water Bottle',
    description: 'Hydro Flask water bottle found in the gym locker room.',
    category: 'Other',
    type: 'found',
    image: 'https://images.unsplash.com/photo-1602143407151-7111542de6e8?w=400',
    poster: 'Lisa M.',
    createdAt: '2026-02-09',
    location: 'Recreation Center',
    status: 'active'
  },
  {
    id: 'lf5',
    title: 'Lost Keys with Red Keychain',
    description: 'Lost my keys with a distinctive red bottle opener keychain. Please contact if found!',
    category: 'Keys',
    type: 'lost',
    image: 'https://images.unsplash.com/photo-1582139329536-e7284fece509?w=400',
    poster: 'Ryan B.',
    createdAt: '2026-02-08',
    location: 'University Hall',
    status: 'active'
  }
];

export const categories = [
  'All',
  'Textbooks',
  'Electronics',
  'Furniture',
  'Clothing',
  'Other'
];

export const lostFoundCategories = [
  'All',
  'Electronics',
  'Bags',
  'Keys',
  'ID/Cards',
  'Clothing',
  'Other'
];
