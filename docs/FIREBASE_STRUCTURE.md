# 🔥 EGO Store Ecosystem — Canonical Firestore Database Schema

This document represents the single unified source of truth for Cloud Firestore database collections, subcollections, document schemas, and field types across both:
- **EGO Admin Panel** (`admin_panel_ego`)
- **EGO E-Commerce Mobile App** (`ecommerce_app-main`)

---

## 1. Top-Level Collections Overview

| # | Collection Name | Purpose | Read Access | Write Access |
|---|-----------------|---------|-------------|--------------|
| 1 | `Users` | User profiles & customer accounts | Public/Owner | Authenticated/Owner/Admin |
| 2 | `Products` | Catalog items (Liquids, Hardware, Pods, Coils, Disposables, Accessories) | Public | Admin Only |
| 3 | `Brands` | Brand directory & logos | Public | Admin Only |
| 4 | `Categories` | Taxonomy classifications | Public | Admin Only |
| 5 | `Banners` | Home & Shop promo banners | Public | Admin Only |
| 6 | `Badges` | High-impact product highlight badges | Public | Admin Only |
| 7 | `Orders` | Customer & POS orders | Customer & Admin | Customer (create), Admin (all) |
| 8 | `Coupons` | Discount coupon codes | Authenticated | Admin Only |
| 9 | `AdminBroadcasts` | Global push notifications & broadcasts | Public/Admin | Admin Only |
| 10 | `Settings` | App settings, RBAC roles & passcodes | Authenticated | Admin / Super Admin |
| 11 | `ContactInfo` | Store contact info & support channels | Public | Admin Only |
| 12 | `suppliers` | Procurement suppliers & vendor directory | Admin Only | Admin Only |
| 13 | `purchase_invoices` | Supplier purchase supply invoices | Admin Only | Admin Only |
| 14 | `supplier_payments` | Supplier payment & disbursement vouchers | Admin Only | Admin Only |
| 15 | `stock_movements` | Immutable audit trail for stock adjustments | Admin Only | Admin Only |
| 16 | `expenses` | General operational expenses (OpEx) | Admin Only | Admin Only |
| 17 | `damaged_stock` | Inventory waste & write-offs | Admin Only | Admin Only |
| 18 | `employees` | Staff directory & employment profiles | Admin Only | Admin Only |
| 19 | `salary_advances` | Staff salary advance disbursements | Admin Only | Admin Only |
| 20 | `payroll_history` | Monthly payroll calculation slips | Admin Only | Admin Only |
| 21 | `pos_sales` | Point-of-Sale shift & cashier transactions | Admin Only | Admin Only |

---

## 2. Detailed Schemas & Canonical Field Names

### 1. `Users` Collection
**Path**: `/Users/{userId}`
```json
{
  "id": "USER_UID",
  "userName": "Amir Gerges",
  "email": "user@example.com",
  "phone": "01000000000",
  "image": "https://firebasestorage.googleapis.com/.../profile.jpg",
  "role": "user",
  "fcmToken": "fcm_device_token_string",
  "createdAt": "TIMESTAMP"
}
```

#### User Subcollections:
- `/Users/{userId}/Addresses/{addressId}`:
  ```json
  {
    "id": "ADDR_01",
    "name": "Home",
    "phoneNumber": "01000000000",
    "street": "123 Nile Street",
    "city": "Cairo",
    "state": "Cairo Governorate",
    "latitude": 30.0444,
    "longitude": 31.2357,
    "selectedAddress": true,
    "dateTime": "TIMESTAMP"
  }
  ```
- `/Users/{userId}/Notifications/{notificationId}`:
  ```json
  {
    "id": "NOTIF_01",
    "title": "Order Confirmed",
    "body": "Your order #ORD-1044 is being prepared.",
    "type": "order_status_update",
    "isRead": false,
    "createdAt": "TIMESTAMP"
  }
  ```
- `/Users/{userId}/Favorites/{productId}`:
  ```json
  {
    "productId": "PROD_01",
    "addedAt": "TIMESTAMP"
  }
  ```
- `/Users/{userId}/Cart/{cartItemId}`:
  ```json
  {
    "productId": "PROD_01",
    "title": "Vaporesso XROS 4 Pod Kit",
    "price": 1450.0,
    "quantity": 1,
    "variationId": "VAR_BLK_06",
    "sku": "XROS4-BLK-06",
    "selectedVariation": {"Color": "Black", "Resistance": "0.6Ω"},
    "image": "https://..."
  }
  ```

---

### 2. `Products` Collection
**Path**: `/Products/{productId}`
```json
{
  "id": "PROD_XROS_4",
  "title": "Vaporesso XROS 4 Pod Kit",
  "description": "Upgraded COREX 2.0 pod system with 1000mAh battery.",
  "price": 1550.0,
  "salePrice": 1450.0,
  "costPrice": 1100.0,
  "stock": 30,
  "lowStockThreshold": 5,
  "images": [
    "https://.../xros4_black.jpg",
    "https://.../xros4_silver.jpg"
  ],
  "brand": {
    "id": "BRAND_VAPORESSO",
    "name": "Vaporesso",
    "image": "https://...",
    "productsCount": 42
  },
  "categoryId": "CAT_POD_SYSTEMS",
  "categoryType": "device",
  "isBadgeEnabled": true,
  "badgeId": "BADGE_HOT",
  "isOnline": true,
  "productType": "variable",
  "productAttributes": [
    {"name": "Color", "values": ["Black", "Silver"]},
    {"name": "Resistance", "values": ["0.4Ω", "0.6Ω"]}
  ],
  "productVariations": [
    {
      "id": "VAR_XROS4_BLK_06",
      "sku": "XROS4-BLK-06",
      "price": 1450.0,
      "salePrice": 1450.0,
      "costPrice": 1100.0,
      "stock": 15,
      "image": "https://...",
      "attributeValues": {"Color": "Black", "Resistance": "0.6Ω"}
    }
  ],
  "specifications": {
    "batteryCapacity": "1000mAh",
    "liquidOrigin": "Premium"
  }
}
```

---

### 3. `Brands` Collection
**Path**: `/Brands/{brandId}`
```json
{
  "id": "BRAND_VAPORESSO",
  "name": "Vaporesso",
  "image": "https://...",
  "parentId": "",
  "isFeatured": true,
  "productsCount": 42,
  "sortOrder": 1
}
```

---

### 4. `Categories` Collection
**Path**: `/Categories/{categoryId}`
```json
{
  "id": "CAT_POD_SYSTEMS",
  "name": "Pod Systems",
  "image": "https://...",
  "parentId": "CAT_HARDWARE",
  "isFeatured": true,
  "sortOrder": 1
}
```

---

### 5. `Banners` Collection
**Path**: `/Banners/{bannerId}`
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

---

### 6. `Badges` Collection
**Path**: `/Badges/{badgeId}`
```json
{
  "id": "BADGE_HOT",
  "name": "Hot Deal",
  "nameAr": "عرض مميز",
  "colorHex": "#EF4444",
  "textColorHex": "#FFFFFF",
  "icon": "local_fire_department",
  "isActive": true,
  "displayOrder": 1
}
```

---

### 7. `Orders` Collection
**Path**: `/Orders/{orderId}`
```json
{
  "id": "ORD-2026-1044",
  "orderId": "#ORD-2026-1044",
  "userId": "USER_UID",
  "customerName": "Amir Gerges",
  "customerEmail": "user@example.com",
  "customerPhone": "01000000000",
  "status": "pending",
  "totalAmount": 1450.0,
  "totalPrice": 1450.0,
  "subTotal": 1450.0,
  "shippingCost": 0.0,
  "taxFee": 0.0,
  "discount": 0.0,
  "couponCode": "",
  "itemsCount": 1,
  "paymentMethod": "Cash on Delivery",
  "paymentStatus": "pending",
  "stockDeducted": true,
  "isRead": false,
  "orderDate": "TIMESTAMP",
  "createdAt": "TIMESTAMP",
  "shippingAddress": {
    "name": "Amir Gerges",
    "phoneNumber": "01000000000",
    "street": "123 Nile Street",
    "city": "Cairo",
    "country": "Egypt"
  },
  "items": [
    {
      "productId": "PROD_XROS_4",
      "title": "Vaporesso XROS 4 Pod Kit",
      "price": 1450.0,
      "quantity": 1,
      "variationId": "VAR_XROS4_BLK_06",
      "sku": "XROS4-BLK-06",
      "image": "https://...",
      "selectedVariation": {"Color": "Black", "Resistance": "0.6Ω"}
    }
  ]
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
  "discountAmount": 0.0,
  "isActive": true,
  "startDate": "TIMESTAMP",
  "expiryDate": "TIMESTAMP",
  "expiresAt": "TIMESTAMP",
  "minOrderAmount": 500.0,
  "usageCount": 14
}
```

---

### 9. `AdminBroadcasts` Collection
**Path**: `/AdminBroadcasts/{broadcastId}`
```json
{
  "id": "BCAST_01",
  "title": "Weekend Flash Sale ⚡",
  "body": "Enjoy 20% off all SaltNic liquids this weekend!",
  "type": "offer",
  "imageUrl": "https://...",
  "targetScreen": "/shop",
  "targetAudience": "All Users",
  "topic": "all_users",
  "sentAt": "TIMESTAMP",
  "createdAt": "TIMESTAMP",
  "isBroadcast": true
}
```

---

### 10. `suppliers` Collection
**Path**: `/suppliers/{supplierId}`
```json
{
  "id": "SUP_01",
  "name": "Vaporesso Official Distributor",
  "contactPerson": "Khaled Hassan",
  "phone": "01011112222",
  "email": "vendor@vaporesso-dist.com",
  "address": "Free Zone, Nasr City, Cairo",
  "taxNumber": "123-456-789",
  "suppliedCategories": ["Hardware", "Pods", "Coils"],
  "defaultPaymentTerms": "30 Days Net",
  "balanceDue": 24500.0,
  "totalPurchases": 185000.0,
  "totalPaid": 160500.0,
  "rating": 5,
  "isActive": true,
  "createdAt": "TIMESTAMP"
}
```

---

### 11. `purchase_invoices` Collection
**Path**: `/purchase_invoices/{invoiceId}`
```json
{
  "id": "INV-2026-088",
  "supplierId": "SUP_01",
  "supplierName": "Vaporesso Official Distributor",
  "referenceNumber": "BILL-99401",
  "invoiceDate": "TIMESTAMP",
  "dueDate": "TIMESTAMP",
  "totalAmount": 15000.0,
  "paidAmount": 5000.0,
  "balanceDue": 10000.0,
  "status": "partial",
  "paymentMethod": "Bank Transfer",
  "items": [
    {
      "productId": "PROD_XROS_4",
      "productTitle": "Vaporesso XROS 4 Pod Kit",
      "variationSku": "XROS4-BLK-06",
      "quantity": 10,
      "unitCost": 1100.0,
      "totalCost": 11000.0
    }
  ]
}
```

---

### 12. `stock_movements` Collection
**Path**: `/stock_movements/{movementId}`
```json
{
  "id": "MOV_01",
  "productId": "PROD_XROS_4",
  "productTitle": "Vaporesso XROS 4 Pod Kit",
  "variationSku": "XROS4-BLK-06",
  "variationAttributes": {"Color": "Black", "Resistance": "0.6Ω"},
  "type": "restock",
  "quantity": 25,
  "previousStock": 5,
  "newStock": 30,
  "costPricePerUnit": 1100.0,
  "totalCost": 27500.0,
  "invoiceNumber": "INV-2026-088",
  "notes": "Incoming shipment restock",
  "performedBy": "Warehouse Manager",
  "createdAt": "TIMESTAMP"
}
```

---

### 13. `expenses` Collection
**Path**: `/expenses/{expenseId}`
```json
{
  "id": "EXP_01",
  "title": "Electricity Bill - September",
  "amount": 2800.0,
  "category": "utilities",
  "paymentMethod": "instapay",
  "date": "TIMESTAMP",
  "recordedBy": "Store Manager",
  "notes": "Main branch electricity consumption",
  "createdAt": "TIMESTAMP"
}
```

---

### 14. `damaged_stock` Collection
**Path**: `/damaged_stock/{damageId}`
```json
{
  "id": "DAM_01",
  "productId": "PROD_XROS_4",
  "productTitle": "Vaporesso XROS 4 Pod Kit",
  "variationSku": "XROS4-BLK-06",
  "variationAttributes": {"Color": "Black", "Resistance": "0.6Ω"},
  "quantity": 2,
  "costPrice": 1100.0,
  "totalFinancialLoss": 2200.0,
  "reason": "shipping_damage",
  "notes": "Broken seal during carrier transit",
  "loggedBy": "Warehouse Clerk",
  "date": "TIMESTAMP",
  "createdAt": "TIMESTAMP"
}
```

---

### 15. `employees` Collection
**Path**: `/employees/{employeeId}`
```json
{
  "id": "EMP_01",
  "name": "Ahmed Mohamed",
  "phone": "01099887766",
  "nationalId": "29801010101234",
  "jobTitle": "Head Cashier",
  "baseSalary": 7500.0,
  "address": "Nasr City, Cairo",
  "emergencyContact": "01122334455",
  "isActive": true,
  "hireDate": "TIMESTAMP",
  "createdAt": "TIMESTAMP"
}
```

---

### 16. `salary_advances` Collection
**Path**: `/salary_advances/{advanceId}`
```json
{
  "id": "ADV_01",
  "employeeId": "EMP_01",
  "employeeName": "Ahmed Mohamed",
  "amount": 1500.0,
  "disbursedDate": "TIMESTAMP",
  "paymentMethod": "cash",
  "payrollMonth": "2026-09",
  "isDeducted": true,
  "notes": "Mid-month advance",
  "disbursedBy": "Finance Manager",
  "createdAt": "TIMESTAMP"
}
```

---

### 17. `payroll_history` Collection
**Path**: `/payroll_history/{payrollId}`
```json
{
  "id": "PAY_01",
  "employeeId": "EMP_01",
  "employeeName": "Ahmed Mohamed",
  "payrollMonth": "2026-09",
  "baseSalary": 7500.0,
  "bonuses": 500.0,
  "advancesDeducted": 1500.0,
  "otherDeductions": 0.0,
  "netSalaryPaid": 6500.0,
  "paymentDate": "TIMESTAMP",
  "disbursedBy": "Finance Manager",
  "recordedToExpenses": true,
  "expenseId": "EXP_PAYROLL_01",
  "createdAt": "TIMESTAMP"
}
```

---

### 18. `Settings` Collection
- `/Settings/store_settings`:
  ```json
  {
    "storeName": "EGO Store",
    "currency": "EGP",
    "deliveryFee": 50.0,
    "freeDeliveryThreshold": 1500.0,
    "taxRate": 0.0,
    "supportPhone": "01012345678",
    "supportWhatsApp": "01012345678",
    "supportEmail": "support@egostore.com",
    "updatedAt": "TIMESTAMP"
  }
  ```
- `/Settings/roles_permissions`: Role permission matrix for RBAC.
- `/Settings/security_passcodes`: PIN codes for elevated Admin & Super Admin actions.
