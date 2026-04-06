# Network Layer — Cloudflare Tunnel & DNS

This layer manages the **ingress** and **edge security** for the Keystone infrastructure using **Cloudflare Zero Trust** and **DNS**.

## Purpose

The Network Layer provides a secure entry point into the AWS environment. While the **Top-Level Domain (TLD) is purchased and managed manually** (outside of this IaC), this layer handles the creation and management of **DNS Hosted Zones**, records, and edge security configurations.

It uses **Cloudflare Tunnels** (`cloudflared`) to establish a persistent, outbound-only connection between the private AWS subnets and the Cloudflare edge, eliminating the need for public-facing endpoints.

## Key Features

*   **DNS & Hosted Zone Management:** Authoritative DNS management for the manually purchased domain.
*   **Cloudflare Zero Trust Tunnels:** Secure, outbound-only connections to Cloudflare.
*   **Edge Security (WAF):** Comprehensive rate-limiting, custom firewall rules, and API protection.
*   **Manage Transforms:** Automatic HTTP header modification for security and geolocation.
*   **Tiered Cache:** Optimizes content delivery performance across the Cloudflare global network.
*   **Email Routing:** Catch-all email forwarding for domain management.

## Modules Used

This layer invokes the following internal modules from `terraform/modules/`:
*   **[cloudflare-tunnel](../../modules/cloudflare-tunnel/README.md)** — Tunnel creation and token management.
*   **[cloudflare-security](../../modules/cloudflare-security/README.md)** — WAF rules and Zero Trust policies.
*   **[cloudflare-dns](../../modules/cloudflare-dns/README.md)** — CNAME records and zone settings.

## Dependencies

This layer is the **first** to be deployed. It provides essential identifiers (Tunnel ID, Token) used by subsequent layers.

- **Secrets:** Cloudflare account and zone IDs are retrieved from **AWS SSM Parameter Store**.
- **Outputs:** Exports the `tunnel_id` and `tunnel_token_secret_arn` for use by the **App Layer**.

