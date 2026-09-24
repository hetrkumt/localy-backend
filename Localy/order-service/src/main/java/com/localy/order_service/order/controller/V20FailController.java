package com.localy.order_service.order.controller;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

/**
 * Temporary endpoint for p5 V20 (intentional 5xx → Analysis abort).
 * Remove after V20 capture + Rollout recovery.
 */
@RestController
public class V20FailController {

    @GetMapping("/v20-fail")
    public ResponseEntity<Map<String, String>> fail() {
        return ResponseEntity
                .status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(Map.of(
                        "status", "500",
                        "purpose", "p5-V20-canary-abort",
                        "message", "intentional failure for SLI abort demo"
                ));
    }
}
