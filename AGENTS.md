# AGENTS.md – Guide for ChatGPT Codex Integration (Updated)

_Last updated: 2025-06-03_

This document provides comprehensive guidance for using **ChatGPT Codex** in this codebase. It defines expectations for code generation, testing, documentation, security, CI/CD, and review. All contributions made by AI agents must follow the standards below to ensure quality, safety, and maintainability.

---

## 📁 Project Structure for Codex Navigation

- `/src`: Application source code
  - `/components`: React components (Codex may extend or create)
  - `/pages`: Next.js pages and routing logic
  - `/styles`: Tailwind CSS styling rules
  - `/utils`: Utility functions Codex can leverage or enhance
- `/public`: Static assets (Codex must **not** alter these)
- `/tests`: Test suites Codex should maintain or generate

---

## 💻 General Coding Conventions

- Use **TypeScript** in all new code
- Match the **existing code style** in any file
- Use meaningful, self-documenting names
- Include comments for complex logic
- Avoid unnecessary abstractions or generic helpers

---

## ⚛️ React Component Standards

- Use **functional components** and React Hooks
- File names must follow **PascalCase** (e.g., `UserCard.tsx`)
- Define props with `interface` or `type`
- Keep components focused on a single concern

---

## 🎨 Tailwind CSS Styling Rules

- Use **Tailwind CSS** utility classes exclusively
- Avoid global CSS unless unavoidable
- Structure layout with utility classes; minimize custom styles

---

## 🧪 Testing Requirements

Codex must generate or update tests for all implemented logic.

```bash
# Run all tests
npm test

# Run a specific test file
npm test -- path/to/file.test.ts

# Run with coverage
npm test -- --coverage
