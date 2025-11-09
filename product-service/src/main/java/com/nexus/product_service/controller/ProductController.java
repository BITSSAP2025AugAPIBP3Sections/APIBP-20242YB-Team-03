package com.nexus.product_service.controller;

import com.nexus.product_service.service.ProductService;

import lombok.RequiredArgsConstructor;

import com.nexus.product_service.model.Product;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import java.util.Optional;

@RestController
@RequiredArgsConstructor
@RequestMapping("api/v1/product")
public class ProductController {
    private final ProductService productService;

    @PostMapping
    public Map<String,String> createProduct(@RequestBody Product product) {
        return Map.of("id", productService.CreateProduct(product));
    }
    @GetMapping
    public List<Product> getAllProducts() {
        return productService.GetAllProducts();
    }

    @GetMapping("/category/{category}")
    public List<Product> getProductsByCategory(@PathVariable String category) {
        return productService.GetProductsByCategory(category);
    }

    @GetMapping("/supplier/{supplierId}")
    public List<Product> getProductsBySupplier(@PathVariable String supplierId) {
        return productService.GetProductsBySupplier(supplierId);
    }
    @GetMapping("/shortage")
    public List<Product> getProductsInShortage() {
        return productService.GetProductsInShortage();
    }
    @GetMapping("/{id}")
    public Optional<Product> getProductById(@PathVariable String id) {
        return productService.getByID(id);
    }
    @PutMapping("/{id}")
    public Map<String, String> updateProduct(@PathVariable String id, @RequestBody Product updatedProduct) {
        boolean updated = productService.updateProduct(id, updatedProduct);
        if (updated) {
            return Map.of("message", "Product updated successfully");
        } else {
            return Map.of("message", "Product not found");  
        }
    }
    @DeleteMapping("/{id}")
    public Map<String, String> deleteProduct(@PathVariable String id) {
        boolean deleted = productService.deleteProduct(id);
        if (deleted) {
            return Map.of("message", "Product deleted successfully");
        } else {
            return Map.of("message", "Product not found");
        }
    }
}
