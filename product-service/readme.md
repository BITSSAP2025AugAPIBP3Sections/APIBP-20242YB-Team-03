# 🛒 Product Service — Nexus Collaboration Supply Chain Platform

This microservice manages **products**, owned and updated by suppliers. It exposes REST APIs to **create, update, delete, and query products**.

---

## ✅ Tech Stack

| Component | Technology                             |
| --------- | -------------------------------------- |
| Language  | Java 21                                |
| Framework | Spring Boot 3.x                        |
| Database  | MongoDB Atlas                          |
| API Docs  | Swagger / OpenAPI                      |
| Security  | JWT Authentication & Role Based Access |

---

## 📦 Responsibilities

* Suppliers can **add products**
* Suppliers can **update / delete** their own products
* Funders & Investors can **view products only**
* System detects **stock shortage** based on `shortageThreshold`

---

## 🌐 Base URL

```
/api/v1/product
```

---

## 🔐 Role-Based Access Control (RBAC)

| Role                                 | Permissions                    |
| ------------------------------------ | ------------------------------ |
| **SUPPLIER**                         | Create, Update, Delete product |
| **FUNDER**, **INVESTOR**, **ANYONE** | View/Search products           |

JWT payload must include:

```json
{
  "role": "SUPPLIER"
}
```

---

## 🧠 API Endpoints

| Method     | Endpoint                                | Description                        | Auth Required |
| ---------- | --------------------------------------- | ---------------------------------- | ------------- |
| **POST**   | `/api/v1/product`                       | Create a new product               | `SUPPLIER`    |
| **GET**    | `/api/v1/product`                       | Fetch all products                 | ❌             |
| **GET**    | `/api/v1/product/{id}`                  | Fetch product by ID                | ❌             |
| **PUT**    | `/api/v1/product/{id}`                  | Update existing product            | `SUPPLIER`    |
| **DELETE** | `/api/v1/product/{id}`                  | Delete a product                   | `SUPPLIER`    |
| **GET**    | `/api/v1/product/category/{category}`   | Filter products by category        | ❌             |
| **GET**    | `/api/v1/product/supplier/{supplierId}` | Fetch products created by supplier | ❌             |
| **GET**    | `/api/v1/product/shortage`              | Fetch shortage products            | ❌             |

---

## 📝 Sample JSON Payloads

### ➕ Create Product

```
POST /api/v1/product
```

```json
{
  "name": "MacBook Pro",
  "category": "Electronics",
  "quantity": 5,
  "price": 2050.00,
  "supplierId": "SUP123",
  "tags": ["Laptop", "Apple"],
  "shortageThreshold": 3
}
```

✅ Response:

```json
{
  "id": "67512adc9013ef..."
}
```

---

### ✏️ Update Product

```
PUT /api/v1/product/{id}
```

```json
{
  "quantity": 10,
  "price": 1989.00
}
```

✅ Response:

```json
{
  "message": "Product updated successfully"
}
```

---

### ❌ Delete Product

```
DELETE /api/v1/product/{id}
```

✅ Response:

```json
{
  "message": "Product deleted successfully"
}
```

---

### 🔍 Fetch All Products

```
GET /api/v1/product
```

✅ Response:

```json
[
  {
    "id": "123",
    "name": "MacBook Pro",
    "quantity": 5,
    "price": 2050.00
  }
]
```

---

### 🚨 Low Stock Items

```
GET /api/v1/product/shortage
```

Returns products whose `quantity < shortageThreshold`.

---

## 📘 Swagger / API Docs

After running the service:

👉 Swagger UI

```
http://localhost:3002/swagger-ui.html
```

👉 OpenAPI Spec

```
http://localhost:3002/v3/api-docs
```

---

## ▶️ Run Application

```
mvn clean install
mvn spring-boot:run
```

---

## 📂 Project Structure

```
src/main/java/com/nexus/product_service
│── controller/        → API Endpoints
│── model/             → MongoDB document
│── repository/        → MongoRepository interfaces
│── service/           → Business logic
│── security/          → JWT filtering + RBAC
```

---

## 🏁 Conclusion

This service enables suppliers to manage inventory while funders/investors can safely browse available products.

> For improvements (Kafka integration, event-driven notifications), raise a PR or discuss with the team.
