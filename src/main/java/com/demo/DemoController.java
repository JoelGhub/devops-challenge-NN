package com.demo;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;
import java.util.Map;

@RestController
public class DemoController {

    @GetMapping("/")
    public Map<String, String> root() {
        return Map.of(
            "app",    "devops-challenge",
            "status", "ok"
        );
    }
}
