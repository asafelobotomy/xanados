# xanadOS Reports Directory Structure

This directory contains all xanadOS reporting data and generated reports, organized for easy access and version control.

## Directory Structure

```
docs/reports/
├── data/           # Raw data files used to generate reports
├── generated/      # Generated reports (HTML, JSON, Markdown)
├── archive/        # Archived/historical reports
└── README.md       # This file
```

## Directory Usage

### `/data/`
- **Purpose**: Stores raw data files used as input for report generation
- **Content**: Performance benchmark data, gaming validation results, system summaries
- **Format**: Plain text files with structured data
- **Naming**: `{type}-{name}-{timestamp}.{extension}`
- **Examples**: 
  - `general-benchmark-20250801-190400.performance_data`
  - `general-gaming-20250801-190400.validation_results`
  - `general-summary-20250801-190401.system_overview`

### `/generated/`
- **Purpose**: Contains all generated reports in various formats
- **Content**: HTML, JSON, and Markdown reports created from data files
- **Formats**: 
  - **HTML**: Professional reports with styling for viewing in browsers
  - **JSON**: Machine-readable structured data for API integration
  - **Markdown**: Human-readable documentation format
- **Naming**: `{type}_report_{timestamp}.{format}`
- **Examples**:
  - `performance_report_20250801_190400.html`
  - `gaming_report_20250801_190400.json`
  - `summary_report_20250801_190401.md`

### `/archive/`
- **Purpose**: Stores older reports to keep the generated directory clean
- **Behavior**: Reports are automatically moved here when limits are exceeded
- **Configuration**: Controlled by `XANADOS_MAX_REPORTS` environment variable
- **Default**: Keeps 10 most recent reports per type

## Integration with xanadOS Scripts

The xanadOS directory and reporting libraries automatically use this structure:

### Directory Functions
- `get_results_dir()` → Returns `docs/reports/generated`
- `get_results_filename()` → Returns full path to `docs/reports/data/{filename}`
- `get_log_filename()` → Returns full path to `docs/reports/generated/{filename}`

### Report Generation
```bash
# Source the libraries
source scripts/lib/directories.sh
source scripts/lib/reports.sh

# Generate data file
data_file="$(get_results_filename "benchmark" "performance_data")"
echo "Performance data..." > "$data_file"

# Generate reports
generate_report "performance" "$data_file" "html,json,md"
```

## Benefits of This Structure

1. **Version Control Friendly**: All reports are part of the project repository
2. **Organized**: Clear separation between raw data and generated reports
3. **Accessible**: Easy to find and share reports with team members
4. **Archived**: Automatic cleanup prevents directory bloat
5. **Documented**: Self-documenting structure with clear purposes

## File Lifecycle

1. **Data Creation**: Raw data files created in `/data/` by testing scripts
2. **Report Generation**: Reports generated in `/generated/` from data files
3. **Archiving**: Older reports moved to `/archive/` automatically
4. **Cleanup**: Archive directory managed separately for long-term storage

## Configuration

### Environment Variables
- `XANADOS_MAX_REPORTS=10` - Maximum reports to keep before archiving
- `XANADOS_ARCHIVE_DAYS=7` - Reserved for future time-based archiving

### Customization
The report generation system can be customized by modifying:
- `scripts/lib/reports.sh` - Report templates and formats
- `scripts/lib/directories.sh` - Directory structure and paths

## Report Types Supported

- **benchmark**: Performance benchmarking results
- **gaming**: Gaming optimization validation
- **system**: System overview and status
- **performance**: Detailed performance analysis  
- **summary**: High-level system summaries

Each type supports HTML, JSON, and Markdown output formats with appropriate styling and structure.

---

*This directory structure is part of the xanadOS Report Generation System (Task 3.2.2)*
