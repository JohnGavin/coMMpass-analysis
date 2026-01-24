# Suggested Updates for CLAUDE.md

## Add to "File Structure" section (line ~215):

```markdown
## File Structure (CRITICAL)

```
R/                    # Package functions ONLY
├── *.R               # Analysis functions
├── dev/              # Development tools
│   └── issues/       # Fix scripts (MUST include in PRs)
└── tar_plans/        # Modular pipeline components (MANDATORY)
    └── plan_*.R      # Each returns list of tar_target()

_targets.R            # ONLY orchestrates plans from R/tar_plans/
vignettes/            # Quarto documentation
plans/                # PLAN_*.md working documents
```

## CRITICAL: Targets Pipeline Structure

**NEVER place pipeline definitions directly in _targets.R**

### Correct Structure:
1. **R/tar_plans/plan_*.R**: Modular pipeline components
   - Each file defines one logical group (e.g., plan_data_acquisition.R)
   - Must return a list of tar_target() objects
   - Example: plan_data_acquisition, plan_quality_control

2. **_targets.R**: Orchestrator ONLY
   ```r
   # Set global options
   tar_option_set(...)

   # Source functions (exclude R/dev/ and R/tar_plans/)
   for (file in list.files("R", pattern = "\\.R$", full.names = TRUE)) {
     if (!grepl("R/(dev|tar_plans)/", file)) source(file)
   }

   # Source and combine plans
   plan_files <- list.files("R/tar_plans", pattern = "^plan_.*\\.R$", full.names = TRUE)
   for (plan_file in plan_files) source(plan_file)

   # Combine all plans
   c(plan_data_acquisition, plan_quality_control, ...)
   ```

### Why This Matters:
- **Modularity**: Plans can be reused across projects
- **Testing**: Individual plans can be tested in isolation
- **Collaboration**: Multiple developers can work on different plans
- **Reproducibility**: Clear separation of concerns
```

## Add to "Critical Rules" section:

```markdown
## Testing Before Commit (MANDATORY)

**NEVER commit without testing:**
1. Enter project-specific Nix environment (./default.sh)
2. Run `tar_validate()` - MUST pass
3. Run `tar_make(names = "config")` - Test at least one target
4. Check GitHub CI will trigger (modify .github/workflows if needed)
5. Include R/dev/issue/fix_*.R script documenting changes

**Common Testing Mistakes:**
- ❌ Testing in wrong Nix environment (e.g., llm instead of project)
- ❌ Not running tar_validate() before commit
- ❌ Assuming CI will run (check workflow triggers!)
- ✅ Always test in project-specific Nix shell
```