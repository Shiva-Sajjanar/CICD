package com.example.devops.controller;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import java.time.Instant;
import java.util.HashMap;
import java.util.Map;

@RestController
public class AppController {

    @GetMapping("/")
    public ResponseEntity<Map<String, Object>> root() {
        Map<String, Object> response = new HashMap<>();
        response.put("message", "DevOps Project 01: Automated CI/CD Pipeline");
        response.put("status", "ONLINE");
        response.put("stack", new String[]{"GitHub", "Jenkins", "Maven", "Docker", "Ansible", "AWS"});
        response.put("timestamp", Instant.now().toString());
        return ResponseEntity.ok(response);
    }

    @GetMapping("/api/health")
    public ResponseEntity<Map<String, String>> healthCheck() {
        Map<String, String> status = new HashMap<>();
        status.put("status", "UP");
        status.put("service", "devops-cicd-app");
        status.put("environment", System.getenv().getOrDefault("APP_ENV", "production"));
        return ResponseEntity.ok(status);
    }

    @GetMapping("/api/pipeline-info")
    public ResponseEntity<Map<String, Object>> pipelineInfo() {
        Map<String, Object> info = new HashMap<>();
        info.put("version", "1.0.0");
        info.put("ci_cd_tool", "Jenkins Declarative Pipeline");
        info.put("deployment_tool", "Ansible");
        info.put("container_engine", "Docker");
        info.put("cloud_platform", "AWS EC2");
        return ResponseEntity.ok(info);
    }
}
