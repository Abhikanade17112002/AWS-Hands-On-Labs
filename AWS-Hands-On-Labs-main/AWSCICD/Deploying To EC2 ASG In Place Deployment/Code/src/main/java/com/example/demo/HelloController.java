package com.example.demo;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class HelloController {

    @GetMapping("/")
    public String hello() {
        return "Hello from Blue/Green Deployment (version 1.0.0)";
    }

    @GetMapping("/version")
    public String version() {
        return "1.0.0";
    }
}