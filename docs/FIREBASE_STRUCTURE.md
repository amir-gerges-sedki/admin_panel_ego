# 🔥 Firebase Cloud Architecture & Database Schema — EGO Store (Vape & Smoking)

## 1. Firebase Suite Services in Use
- **Firebase Authentication**: Email/Password, Google OAuth, Facebook Auth, Session tokens, Password reset.
- **Cloud Firestore**: Primary NoSQL cloud database for catalog, orders, and user data.
- **Firebase Cloud Messaging (FCM)**: Remote push notifications, background data messages, topics.
- **Firebase Storage**: Product images, liquids, hardware kits, brand logos, and banners.
- **Firebase Analytics**: User journey tracking and e-commerce conversion events.

---

## 2. Cloud Firestore Collections & Schemas

### 1. `Users` Collection
**Path**: `/Users/{userId}`
```json
{
  "id": "USER_UID_STRING",
  "name": "Amir Gerges",
  "userName": "Amir Gerges",
  "email": "user@example.com",
  "phone": "01000000000",
  "image": "https://firebasestorage.googleapis.com/.../profile.jpg",
  "fcmToken": "fcm_device_token_string",
  "role": "user",
  "createdAt": "TIMESTAMP"
}
```

#### Sub-collections under `/Users/{userId}`:
- **`Addresses`** (`/Users/{userId}/Addresses/{addressId}`):
  ```json
  {
    "id": "ADDR_01",
    "name": "Home",
    "phoneNumber": "01000000000",
    "street": "123 Nile Street",
    "city": "Cairo",
    "state": "Cairo Governorate",
    "postalCode": "11511",
    "country": "Egypt",
    "latitude": 30.0444,
    "longitude": 31.2357,
    "selectedAddress": true
  }
  ```
- **`Favorites`** (`/Users/{userId}/Favorites/{productId}`):
  ```json
  {
    "productId": "PROD_VAP_001",
    "addedAt": "TIMESTAMP"
  }
  ```
- **`Cart`** (`/Users/{userId}/Cart/{cartItemId}`):
  ```json
  {
    "productId": "PROD_VAP_001",
    "title": "Vaporesso XROS 4 Pod Kit",
    "price": 1450.0,
    "quantity": 1,
    "variationId": "VAR_BLK",
    "selectedVariation": {"Color": "Black", "Resistance": "0.6Ω"},
    "image": "https://..."
  }
  ```

---

### 2. `Products` Collection (Vape Hardware & E-Liquids)
**Path**: `/Products/{productId}`

#### Example A: Hardware / Pod Kit Product
```json
{
  "id": "PROD_XROS_4",
  "title": "Vaporesso XROS 4 Pod System Kit",
  "description": "Upgraded COREX 2.0 pod system with 1000mAh battery and 3-level output adjustment.",
  "price": 1550.0,
  "salePrice": 1450.0,
  "stock": 30,
  "thumbnail": "https://firebasestorage.googleapis.com/.../xros4_thumb.jpg",
  "images": [
    "https://firebasestorage.googleapis.com/.../xros4_black.jpg",
    "https://firebasestorage.googleapis.com/.../xros4_silver.jpg",
    "https://firebasestorage.googleapis.com/.../xros4_blue.jpg"
  ],
  "brand": {
    "id": "BRAND_VAPORESSO",
    "name": "Vaporesso",
    "image": "https://...",
    "productsCount": 42
  },
  "categoryId": "CAT_POD_SYSTEMS",
  "productType": "variable",
  "productAttributes": [
    {"name": "Color", "values": ["Black", "Silver", "Midnight Blue"]},
    {"name": "Resistance", "values": ["0.4Ω", "0.6Ω", "0.8Ω"]}
  ],
  "productVariations": [
    {
      "id": "VAR_XROS4_BLK_06",
      "sku": "XROS4-BLK-06",
      "price": 1450.0,
      "salePrice": 1450.0,
      "stock": 12,
      "image": "https://...",
      "attributeValues": {"Color": "Black", "Resistance": "0.6Ω"}
    }
  ],
  "rating": 4.9,
  "totalReviews": 89
}
```

#### Example B: E-Liquid / Salt Nicotine Product
```json
{
  "id": "PROD_VGOD_CUBANO",
  "title": "VGOD SaltNic Cubano 30ml",
  "description": "Rich cigar tobacco with a smooth touch of creamy vanilla.",
  "price": 550.0,
  "salePrice": 499.0,
  "stock": 60,
  "thumbnail": "https://firebasestorage.googleapis.com/.../cubano.jpg",
  "images": ["https://firebasestorage.googleapis.com/.../cubano.jpg"],
  "brand": {
    "id": "BRAND_VGOD",
    "name": "VGOD",
    "image": "https://...",
    "productsCount": 28
  },
  "categoryId": "CAT_SALT_NIC",
  "productType": "variable",
  "productAttributes": [
    {"name": "Nicotine", "values": ["25mg", "50mg"]},
    {"name": "Size", "values": ["30ml"]}
  ],
  "productVariations": [
    {
      "id": "VAR_CUBANO_50MG",
      "sku": "VGOD-CUB-50MG",
      "price": 499.0,
      "salePrice": 499.0,
      "stock": 25,
      "image": "https://...",
      "attributeValues": {"Nicotine": "50mg", "Size": "30ml"}
    }
  ],
  "rating": 4.8,
  "totalReviews": 114
}
```

---

### 3. `Categories` Collection (Vape Taxonomy)
**Path**: `/Categories/{categoryId}`
```json
{
  "id": "CAT_SALT_NIC",
  "name": "Salt Nicotine",
  "image": "https://...",
  "parentId": "CAT_E_LIQUIDS",
  "isFeatured": true
}
```
*Standard Vape Categories in EGO Store*:
- `CAT_HARDWARE` (Vape Kits & Mods)
- `CAT_POD_SYSTEMS` (Pod Systems)
- `CAT_SALT_NIC` (Salt Nicotine E-Liquids)
- `CAT_FREEBASE` (Freebase E-Liquids)
- `CAT_COILS_PODS` (Replacement Coils & Cartridges)
- `CAT_DISPOSABLES` (Disposable Vapes)
- `CAT_ACCESSORIES` (Batteries, Chargers, Cotton & Tools)

---

### 4. `Brands` Collection (Vape Manufacturers)
**Path**: `/Brands/{brandId}`
```json
{
  "id": "BRAND_GEEKVAPE",
  "name": "GeekVape",
  "image": "https://...",
  "isFeatured": true,
  "productsCount": 35
}
```
*Featured Brands*: *Vaporesso, GeekVape, Voopoo, SMOK, VGOD, Nasty Juice, Uwell, Dinner Lady, Rincoe, Oxva*.

---

### 5. `Banners` Collection
**Path**: `/Banners/{bannerId}`

**Sponsored Product Banner Example:**
```json
{
  "id": "BANNER_XROS_PROMO",
  "title": "Vaporesso XROS 4 Special Deal",
  "imageUrl": "https://...",
  "targetScreen": "/productDetailsScreen",
  "targetType": "product",
  "productId": "PROD_XROS_4",
  "productTitle": "Vaporesso XROS 4 Pod Kit",
  "active": true
}
```

**General / Category Banner Example:**
```json
{
  "id": "BANNER_SALTNIC_DEAL",
  "title": "Weekend Flavors Sale",
  "imageUrl": "https://...",
  "targetScreen": "/shop",
  "targetType": "custom",
  "active": true
}
```

---

### 6. `Orders` Collection
**Path**: `/Orders/{orderId}`
```json
{
  "id": "ORD-2026-1044",
  "userId": "USER_UID",
  "status": "Processing",
  "orderDate": "TIMESTAMP",
  "deliveryDate": "TIMESTAMP",
  "items": [
    {
      "productId": "PROD_XROS_4",
      "title": "Vaporesso XROS 4 Pod Kit",
      "price": 1450.0,
      "quantity": 1,
      "selectedVariation": {"Color": "Black", "Resistance": "0.6Ω"},
      "image": "https://..."
    },
    {
      "productId": "PROD_VGOD_CUBANO",
      "title": "VGOD SaltNic Cubano 30ml",
      "price": 499.0,
      "quantity": 2,
      "selectedVariation": {"Nicotine": "50mg", "Size": "30ml"},
      "image": "https://..."
    }
  ],
  "paymentMethod": "Cash on Delivery",
  "shippingAddress": {
    "name": "Amir Gerges",
    "phoneNumber": "01000000000",
    "street": "123 Nile Street",
    "city": "Cairo"
  },
  "subTotal": 2448.0,
  "shippingCost": 0.0,
  "taxFee": 0.0,
  "discount": 100.0,
  "totalAmount": 2348.0
}
```

---

### 7. `Notifications` Collection
**Path**: `/Notifications/{notificationId}`
```json
{
  "id": "NOTIF_01",
  "userId": "USER_UID",
  "title": "Order #ORD-2026-1044 Confirmed",
  "body": "Your vape order has been placed and is currently being prepared.",
  "type": "order",
  "data": {"orderId": "ORD-2026-1044"},
  "read": false,
  "createdAt": "TIMESTAMP"
}
```

---

### 8. `Coupons` Collection
**Path**: `/Coupons/{couponCode}`
```json
{
  "id": "COUPON_VAPE20",
  "code": "VAPE20",
  "discountPercentage": 20.0,
  "isActive": true,
  "expiryDate": "TIMESTAMP"
}
```

---

### 9. `ContactInfo` Collection
**Path**: `/ContactInfo/support`
```json
{
  "phoneNumber": "01012345678",
  "whatsNumber": "01012345678",
  "email": "support@egostore.com",
  "address": "Cairo, Egypt"
}
```

---

## 3. Recommended Security Rules Architecture

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    function isAuthenticated() { return request.auth != null; }
    function isOwner(userId) { return isAuthenticated() && request.auth.uid == userId; }

    // Public Read Catalog
    match /Products/{id} { allow read: if true; allow write: if false; }
    match /Categories/{id} { allow read: if true; allow write: if false; }
    match /Brands/{id} { allow read: if true; allow write: if false; }
    match /Banners/{id} { allow read: if true; allow write: if false; }
    match /ContactInfo/{id} { allow read: if true; allow write: if false; }
    match /Coupons/{id} { allow read: if isAuthenticated(); allow write: if false; }

    // User Data Isolation
    match /Users/{userId} {
      allow read, write: if isOwner(userId);
      match /Addresses/{addressId} { allow read, write: if isOwner(userId); }
      match /Favorites/{favId} { allow read, write: if isOwner(userId); }
      match /Cart/{cartId} { allow read, write: if isOwner(userId); }
    }

    // Orders Access
    match /Orders/{orderId} {
      allow read: if isAuthenticated() && resource.data.userId == request.auth.uid;
      allow create: if isAuthenticated() && request.resource.data.userId == request.auth.uid;
      allow update, delete: if false;
    }

    // User Notifications
    match /Notifications/{notificationId} {
      allow read, update: if isAuthenticated() && resource.data.userId == request.auth.uid;
      allow create, delete: if false;
    }
  }
}
```
