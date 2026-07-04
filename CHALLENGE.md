# Platform Engineering Challenge

## Overview

This repository describes a set of real-world infrastructure and developer experience challenges. Your task is to evaluate the problems presented, understand their impact, and propose a solution that addresses them — detailing the tools, patterns, and workflows you would adopt.

## Problems to Solve

### 1. Manual Infrastructure Provisioning

**Problem:** Developers need to ask the infrastructure team to create AWS resources for their applications across different environments (dev, staging, production).

**Current Pain Points:**

* Manual ticket-based process for resource creation
* Long lead times for new environments
* Inconsistent resource configurations
* No self-service capabilities

### 2. Configuration Drift and Mapping Issues

**Problem:** Developers need to manually map resources from different environments to their applications and ensure configurations don't drift.

**Current Pain Points:**

* Hard-coded configuration values in `application.properties`
* No automated way to sync infrastructure outputs with application configs
* Risk of misconfiguration between environments
* Manual verification of resource connectivity

### 3. Cross-Team Resource Access

**Problem:** Engineers from one team want to access resources owned by other teams.

**Current Pain Points:**

* No standardized way to share resources across teams
* Unclear ownership and access patterns
* Security and compliance concerns
* Manual coordination required

### 4. Poor Local Development Experience

**Problem:** There is no good way to work locally.

**Current Pain Points:**

* Application requires external AWS resources to run
* No local alternatives for Redis/S3
* Developers must connect to shared dev resources
* Difficult to test infrastructure changes locally
* No containerization or local orchestration

### 5. Documentation Adoption and Platform Support Scalability

**Problem:** Even when documentation exists, developers often do not read it or are unsure how to use the platform tools correctly.

**Current Pain Points:**

* Existing documentation is not consistently followed by engineering teams
* Developers may use platform tools incorrectly or rely on the platform team for basic usage
* Repeated support requests are created for issues that are already documented
* Platform engineers spend time on manual support instead of improving tooling and automation
* Lack of adoption reduces the scalability of the platform team

## Your Task

As a Senior Platform Engineer, you should:

1. Analyze the current setup and identify additional problems
2. Design a comprehensive solution that addresses all five problems
3. Propose specific tools, patterns, and workflows
4. Create an implementation plan with priorities
5. Consider scalability, security, and maintainability

## Implementation Scope

You are not expected to implement the entire platform or solve every problem with production-ready code.

Instead, choose one representative module or workflow and implement it as you would actually ship it to production. For example, you may focus on ECS Fargate service provisioning, configuration management, local development orchestration, or cross-team resource access.

The code you submit should be production-grade for the slice you choose — the kind of code you would genuinely deploy and maintain — rather than pseudocode or a throwaway prototype. We are less interested in breadth than in seeing real, defensible engineering decisions on a focused part of the problem.

The goal is to evaluate how you think, how you make technical decisions, and whether you understand the trade-offs behind your implementation. Your explanation should make clear why you chose that module, how your implementation works, and how it would scale into the broader platform.

## Expected Deliverables

1. **Analysis Document:** Detailed breakdown of current problems and their impact
2. **Solution Architecture:** High-level design of your proposed improvements
3. **Implementation Plan:** Step-by-step approach with timelines and priorities
4. **Code Examples:** A real, production-grade implementation of one representative module or workflow of your choice. You are not expected to build the entire platform — pick one slice, implement it the way you would actually run it in production, and explain why you chose it, how it works, and how it would evolve as the platform grows.
5. **Documentation:** How teams would use your proposed solution

## Evaluation Criteria

* **Problem Identification:** How well you understand and articulate the challenges
* **Solution Design:** Quality and completeness of your architectural approach
* **Technical Implementation:** Practical and realistic solutions
* **Developer Experience:** How much your solution improves day-to-day workflows
* **Scalability:** Can your solution handle growth in teams and applications?
* **Security:** Have you considered security implications and best practices?

## Questions to Consider

* How would you enable self-service infrastructure provisioning?
* What tools would you use for configuration management?
* How would you implement cross-team resource sharing securely?
* What would an ideal local development workflow look like?
* How would you handle containerization and local orchestration?
* What observability and monitoring would you add?
* How would you ensure compliance and governance?
* What CI/CD improvements would you implement?
* How would you ensure platform documentation is discoverable, adopted, and consistently followed by engineering teams?
* Which part of the platform would you choose to implement first, and why?
