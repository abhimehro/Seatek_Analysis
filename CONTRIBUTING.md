# Contributing to Seatek_Analysis

Thank you for your interest in contributing to **Seatek_Analysis**! We welcome contributions from researchers, data scientists, developers, and anyone passionate about environmental data, reproducible science, and open collaboration.

This guide outlines our workflow, label conventions, and best practices to ensure clarity, transparency, and scientific rigor in all contributions.

---

## 1. How to Contribute

- **Bug Reports & Feature Requests:**  
  Please use [GitHub Issues](https://github.com/abhimehro/Seatek_Analysis/issues) to report bugs, request features, or suggest improvements.  
  When reporting, provide as much context as possible, including steps to reproduce, expected behavior, and relevant data or logs.

- **Pull Requests:**  
  1. Fork the repository and create a new branch for your changes.
  2. Write clear, well-documented code and include tests or data examples where appropriate.
  3. Reference related issues or discussions in your PR description.
  4. Assign appropriate labels (see below) to help us categorize your contribution.
  5. Submit your pull request and participate in the review process.

---

## 2. Label Conventions

To maintain a clear and informative changelog, we use a set of standardized labels for issues and pull requests. Please apply the most relevant labels to your contribution. This helps automate our changelog and supports transparent, reproducible project history.

### **Core Label Groups**

| Label Group         | Example Labels                | Purpose/Section in Changelog         |
|---------------------|------------------------------|--------------------------------------|
| **Enhancements**    | `enhancement`, `type: enhancement` | New features, improvements           |
| **Bug Fixes**       | `bug`, `type: bug`           | Fixes for errors or unexpected behavior |
| **Breaking Changes**| `breaking`, `backwards incompatible` | Changes that require user action or may break existing workflows |
| **Deprecated**      | `deprecated`                 | Features or methods scheduled for removal |
| **Removed**         | `removed`                    | Features or code that have been removed |
| **Security**        | `security`                   | Security-related fixes or updates     |
| **Data Updates**    | `data update`, `dataset`     | Updates to datasets or data sources   |
| **Analysis**        | `analysis`, `results`        | New or updated analyses, results, or methods |
| **Documentation**   | `documentation`              | Improvements to docs, guides, or READMEs |

**Excluded Labels:**  
The following labels are excluded from the changelog:  
`duplicate`, `question`, `invalid`, `wontfix`, `Meta: Exclude From Changelog`

**Unlabeled Issues/PRs:**  
If an issue or PR does not have a label, it will still be included in the changelog under a general section.

---

## 3. Best Practices for Contributions

- **Clarity & Rigor:**  
  Write clear commit messages and PR descriptions. Summarize the impact of your changes, especially for data or analysis updates.
- **Reproducibility:**  
  For data or analysis contributions, include code, data sources, and documentation to support reproducibility.
- **Transparency:**  
  Reference related issues, datasets, or publications where relevant.
- **Collaboration:**  
  Engage in discussions, respond to feedback, and help review others’ contributions.

---

## 4. Automated Changelog

We use [github_changelog_generator](https://github.com/github-changelog-generator/github-changelog-generator) to automate our changelog.  
**How it works:**
- The changelog groups changes by label, using the conventions above.
- Each release includes merged pull requests, closed issues, and highlights for breaking changes, enhancements, bug fixes, and more.
- The changelog is updated automatically on each push to `main`.

**Tip:**  
To ensure your contribution is categorized correctly, apply the most relevant label(s) when opening or updating an issue or PR.

---

## 5. Additional Resources

- [Code of Conduct](./CODE_OF_CONDUCT.md)
- [Project Wiki](https://github.com/abhimehro/Seatek_Analysis/wiki)
- [Changelog](./CHANGELOG.md)

---

## 6. Questions or Suggestions?

If you have questions about contributing, label usage, or want to propose new label categories, please open an issue or start a discussion.  
We value clear communication, scientific integrity, and collaborative problem-solving.

---

*Let’s build a transparent, impactful, and reproducible project together!*

---

**Checkpoint:**  
This guide is a living document. As our project and community evolve, so will our conventions and best practices. If you notice ambiguity or have suggestions for improvement, please let us know.

---

**Next Steps:**  
- Review open issues and PRs for opportunities to contribute.
- When submitting, use the label table above to guide your label selection.
- If you’re unsure which label to use, ask in your PR or issue description—maintainers will help categorize it.
