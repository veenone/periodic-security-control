# Periodic Security Control - Redmine Plugin

A comprehensive Redmine plugin for managing periodic security controls using issues as activity trackers. This plugin transforms Excel-based security control tracking into an integrated, automated system within Redmine.

[![Redmine Plugin](https://img.shields.io/badge/Redmine-5.x%20%7C%206.x-green.svg)](https://www.redmine.org/)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

## Table of Contents

- [Features](#features)
- [Screenshots](#screenshots)
- [Requirements](#requirements)
- [Installation](#installation)
- [Configuration](#configuration)
- [Quick Start](#quick-start)
- [Usage Guide](#usage-guide)
- [Database Schema](#database-schema)
- [Architecture](#architecture)
- [Rake Tasks](#rake-tasks)
- [Permissions](#permissions)
- [API Reference](#api-reference)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)
- [License](#license)

## Features

### Core Features

- **Control Categories**: Organize security controls into logical categories (e.g., ACS - Access Control System, AMS - Alarm Management System)
- **Control Points**: Define individual control points with configurable frequencies and assignments
- **Automated Scheduling**: Auto-generate schedules for weekly, monthly, quarterly, semi-annual, and yearly controls
- **Issue Integration**: Automatically create Redmine issues from scheduled controls
- **Status Synchronization**: Auto-sync schedule status when linked issues are closed

### Dashboard & Reporting

- **Global Dashboard**: Overview of all security controls with completion metrics
- **Monthly Progress Chart**: Visual representation of completion rates by month
- **Overdue Alerts**: Highlight controls that have passed their due dates
- **Category Breakdown**: Statistics per control category
- **Calendar View**: Visual calendar showing scheduled controls

### Administration

- **User-Configurable**: All control IDs, naming conventions, and frequencies are manageable by users
- **Import/Export**: Bulk import/export categories and control points via CSV
- **Issue Templates**: Customizable issue subject and description templates with variables
- **Cron Integration**: Rake tasks for automated issue generation and status updates

## Screenshots

### Dashboard
```
┌─────────────────────────────────────────────────────────────────────────┐
│ Periodic Security Controls Dashboard                    Year: [2026 ▼] │
├─────────────────────────────────────────────────────────────────────────┤
│  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐ ┌──────────────┐   │
│  │   TOTAL      │ │  COMPLETED   │ │   PENDING    │ │   OVERDUE    │   │
│  │    156       │ │     89       │ │     52       │ │     15       │   │
│  │   controls   │ │    (57%)     │ │    (33%)     │ │    (10%)     │   │
│  └──────────────┘ └──────────────┘ └──────────────┘ └──────────────┘   │
│                                                                         │
│  Monthly Completion Status                                              │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │ Jan  Feb  Mar  Apr  May  Jun  Jul  Aug  Sep  Oct  Nov  Dec      │   │
│  │ ██   ██   ██   ██   ██   ▓▓   ▒▒   ░░   ░░   ░░   ░░   ░░      │   │
│  │ 100% 100% 100% 95%  90%  75%  30%  0%   0%   0%   0%   0%       │   │
│  └─────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────┘
```

### Category Management
```
┌─────────────────────────────────────────────────────────────────┐
│ Security Control Categories                    [+ New Category] │
├─────────────────────────────────────────────────────────────────┤
│ ┌─────┬──────────────────────────────┬────────┬────────┬─────┐ │
│ │ # ↕ │ Category                     │ Code   │Controls│ Act │ │
│ ├─────┼──────────────────────────────┼────────┼────────┼─────┤ │
│ │ 1   │ Access Control System        │ ACS    │ 17     │ ✓   │ │
│ │ 2   │ Alarm Management System      │ AMS    │ 6      │ ✓   │ │
│ │ 3   │ Video Surveillance System    │ VSS    │ 3      │ ✓   │ │
│ │ 4   │ Visitor Access Management    │ VAM    │ 2      │ ✓   │ │
│ │ 5   │ Incident & Risk Management   │ IRM    │ 3      │ ✓   │ │
│ │ 6   │ Security Operational Mgmt    │ OPM    │ 7      │ ✓   │ │
│ │ 7   │ Test Cards Management        │ TCM    │ 2      │ ✓   │ │
│ └─────┴──────────────────────────────┴────────┴────────┴─────┘ │
└─────────────────────────────────────────────────────────────────┘
```

## Requirements

| Component | Version |
|-----------|---------|
| Redmine | 5.0+ or 6.0+ |
| Ruby | 2.7+ (3.1+ for Redmine 6) |
| Rails | 6.1+ (7.x for Redmine 6) |
| Database | MySQL, PostgreSQL, or SQLite |

## Installation

### Step 1: Download the Plugin

```bash
cd /path/to/redmine/plugins

# Option A: Clone from repository
git clone https://github.com/yourorg/periodic_security_control.git

# Option B: Copy the folder directly
cp -r /path/to/periodic_security_control .
```

### Step 2: Install Dependencies

```bash
cd /path/to/redmine
bundle install
```

### Step 3: Run Database Migrations

```bash
# For production
bundle exec rake redmine:plugins:migrate RAILS_ENV=production

# For development
bundle exec rake redmine:plugins:migrate
```

### Step 4: Restart Redmine

```bash
# Using Passenger
touch tmp/restart.txt

# Using Puma
bundle exec pumactl restart

# Using systemd
sudo systemctl restart redmine
```

### Step 5: Verify Installation

1. Go to **Administration > Plugins**
2. Confirm "Periodic Security Control" appears in the list
3. Click **Configure** to set up the plugin

## Configuration

### Plugin Settings

Navigate to **Administration > Plugins > Periodic Security Control > Configure**

#### General Settings

| Setting | Description | Default |
|---------|-------------|---------|
| Default Project | Project where issues will be created | (none) |
| Issue Author | User set as the issue author | Current user |
| Advance Days | Days before scheduled date to generate issues | 7 |
| Enable Auto Generation | Whether to auto-generate issues via cron | Yes |

#### Issue Templates

Configure templates for auto-generated issues using variables:

**Subject Template:**
```
[{{control_id}}] {{control_name}} - {{period}} {{year}}
```

**Description Template:**
```
Security Control Check

Category: {{category}}
Control: {{control_id}} - {{control_name}}
Period: {{period}} {{year}}
Frequency: {{frequency}}
Scheduled Date: {{scheduled_date}}
Due Date: {{due_date}}
```

#### Available Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `{{control_id}}` | Control ID | ACS01 |
| `{{control_name}}` | Control point name | Badge Audit Review |
| `{{category}}` | Category name | Access Control System |
| `{{period}}` | Period label | January, Q1, Week 5 |
| `{{year}}` | Year number | 2026 |
| `{{frequency}}` | Frequency label | Monthly |
| `{{scheduled_date}}` | Scheduled date | 2026-01-01 |
| `{{due_date}}` | Due date | 2026-01-31 |

### Cron Setup

Add the following to your crontab for automated processing:

```bash
# Edit crontab
crontab -e

# Add these lines:

# Daily at 6 AM - generate issues for due schedules
0 6 * * * cd /path/to/redmine && RAILS_ENV=production bundle exec rake periodic_security_control:generate_issues >> log/psc_cron.log 2>&1

# Daily at midnight - update overdue statuses
0 0 * * * cd /path/to/redmine && RAILS_ENV=production bundle exec rake periodic_security_control:update_overdue >> log/psc_cron.log 2>&1

# December 1st - generate next year schedules
0 0 1 12 * cd /path/to/redmine && RAILS_ENV=production bundle exec rake periodic_security_control:generate_next_year_schedules >> log/psc_cron.log 2>&1

# Weekly on Sunday - sync completed from closed issues
0 2 * * 0 cd /path/to/redmine && RAILS_ENV=production bundle exec rake periodic_security_control:sync_completed >> log/psc_cron.log 2>&1
```

## Quick Start

### Option 1: Load Sample Data

```bash
bundle exec rake periodic_security_control:seed RAILS_ENV=production
```

This creates 7 categories with 40 control points based on common security control standards.

### Option 2: Manual Setup

1. **Create Categories**
   - Go to **Administration > Security Controls**
   - Click **New Category**
   - Enter code (e.g., "ACS") and name (e.g., "Access Control System")

2. **Add Control Points**
   - Click on a category
   - Click **New Control Point**
   - Enter control ID, name, and frequency

3. **Generate Schedules**
   - From the category page, click **Generate [Year] Schedules**
   - Or use: `rake periodic_security_control:generate_schedules[2026]`

4. **Configure Default Project**
   - Go to plugin settings
   - Select the project for issue creation

## Usage Guide

### Dashboard

Access via **Security Controls** in the top menu.

**Features:**
- Summary cards showing total, completed, pending, and overdue counts
- Monthly progress bar chart
- Lists of overdue and upcoming controls
- Category breakdown with completion rates
- Year selector for historical data

### Managing Categories

**Location:** Administration > Security Controls

**Actions:**
- Create new categories with unique codes (2-5 uppercase letters)
- Edit category details
- Delete empty categories
- Import/export via CSV

**CSV Format for Import:**
```csv
code,name,description,active,control_id,control_name,control_description,frequency,control_active
ACS,Access Control System,Physical access controls,true,ACS01,Badge Audit,Monthly badge audit,monthly,true
```

### Managing Control Points

**Location:** Click on a category

**Actions:**
- Create control points with unique IDs
- Set frequency (weekly, monthly, quarterly, six_monthly, yearly)
- Assign default tracker, priority, and assignee
- Generate schedules for specific years

### Managing Schedules

**Location:** Security Controls > Schedules (or via dashboard)

**Actions:**
- Filter by year, status, or category
- Generate issues for pending schedules
- Mark schedules as complete or skipped
- View calendar for visual scheduling
- Bulk generate issues for all due schedules

### Issue Integration

When an issue is created from a schedule:
- The issue is linked to the schedule
- Issue details page shows linked control information
- Closing the issue automatically marks the schedule as completed
- Reopening the issue reverts the schedule status

## Database Schema

### Entity Relationship Diagram

```
┌─────────────────────────────────────┐
│ psc_control_categories              │
├─────────────────────────────────────┤
│ id (PK)                             │
│ name (string)                       │
│ code (string, unique)               │
│ description (text)                  │
│ position (integer)                  │
│ active (boolean)                    │
│ created_at, updated_at              │
└─────────────────────────────────────┘
           │
           │ 1:N
           ▼
┌─────────────────────────────────────┐
│ psc_control_points                  │
├─────────────────────────────────────┤
│ id (PK)                             │
│ category_id (FK)                    │
│ control_id (string, unique)         │
│ name (string)                       │
│ description (text)                  │
│ frequency (string)                  │
│ position (integer)                  │
│ active (boolean)                    │
│ tracker_id (FK, optional)           │
│ priority_id (FK, optional)          │
│ assigned_to_id (FK, optional)       │
│ created_at, updated_at              │
└─────────────────────────────────────┘
           │
           │ 1:N
           ▼
┌─────────────────────────────────────┐
│ psc_schedules                       │
├─────────────────────────────────────┤
│ id (PK)                             │
│ control_point_id (FK)               │
│ year (integer)                      │
│ period_number (integer)             │
│ scheduled_date (date)               │
│ due_date (date)                     │
│ issue_id (FK, nullable)             │
│ status (string)                     │
│ generated_at (datetime)             │
│ completed_at (datetime)             │
│ notes (text)                        │
│ created_at, updated_at              │
└─────────────────────────────────────┘

┌─────────────────────────────────────┐
│ psc_settings                        │
├─────────────────────────────────────┤
│ id (PK)                             │
│ project_id (FK, unique)             │
│ default_tracker_id (FK)             │
│ default_priority_id (FK)            │
│ issue_subject_template (string)     │
│ issue_description_template (text)   │
│ advance_days (integer)              │
│ enable_auto_generation (boolean)    │
│ created_at, updated_at              │
└─────────────────────────────────────┘
```

### Schedule Statuses

| Status | Description |
|--------|-------------|
| `pending` | Awaiting issue generation |
| `generated` | Issue created, awaiting completion |
| `completed` | Control activity completed |
| `overdue` | Past due date without completion |
| `skipped` | Intentionally skipped |

### Frequency Values

| Value | Periods/Year | Description |
|-------|--------------|-------------|
| `weekly` | 52 | Every week (Monday) |
| `monthly` | 12 | First of each month |
| `quarterly` | 4 | January, April, July, October |
| `six_monthly` | 2 | January and July |
| `yearly` | 1 | January 1st |

## Architecture

### File Structure

```
periodic_security_control/
├── app/
│   ├── controllers/
│   │   ├── psc_categories_controller.rb
│   │   ├── psc_control_points_controller.rb
│   │   ├── psc_dashboard_controller.rb
│   │   ├── psc_schedules_controller.rb
│   │   └── psc_settings_controller.rb
│   ├── helpers/
│   │   └── psc_dashboard_helper.rb
│   ├── models/
│   │   ├── psc_control_category.rb
│   │   ├── psc_control_point.rb
│   │   ├── psc_schedule.rb
│   │   └── psc_setting.rb
│   ├── services/
│   │   └── psc_schedule_generator.rb
│   └── views/
│       ├── psc_categories/
│       ├── psc_control_points/
│       ├── psc_dashboard/
│       ├── psc_schedules/
│       ├── settings/
│       └── hooks/
├── assets/
│   ├── javascripts/
│   └── stylesheets/
├── config/
│   ├── locales/
│   │   └── en.yml
│   └── routes.rb
├── db/
│   └── migrate/
├── lib/
│   ├── periodic_security_control/
│   │   ├── hooks.rb
│   │   └── issue_patch.rb
│   └── tasks/
│       └── periodic_security_control.rake
├── init.rb
└── README.md
```

### Key Components

| Component | Description |
|-----------|-------------|
| `init.rb` | Plugin registration, permissions, menus |
| `PscScheduleGenerator` | Service class for schedule/issue generation |
| `IssuePatch` | Extends Issue model for status sync |
| `Hooks` | View hooks for issue details and sidebar |

### Redmine Integration Points

- **Menus**: Application menu (dashboard), Admin menu (categories)
- **Permissions**: Project module with granular permissions
- **Hooks**: `view_issues_show_details_bottom`, `view_projects_show_sidebar_bottom`
- **Settings**: Global plugin settings with partial

## Rake Tasks

| Task | Description |
|------|-------------|
| `periodic_security_control:generate_issues` | Generate issues for due schedules |
| `periodic_security_control:update_overdue` | Mark past-due schedules as overdue |
| `periodic_security_control:generate_schedules[YEAR]` | Generate schedules for a year |
| `periodic_security_control:generate_next_year_schedules` | Generate next year's schedules |
| `periodic_security_control:sync_completed` | Sync from closed issues |
| `periodic_security_control:statistics[YEAR]` | Display statistics |
| `periodic_security_control:daily` | Run all daily tasks |
| `periodic_security_control:seed` | Load sample data |
| `periodic_security_control:cleanup` | Remove orphaned schedules |

### Examples

```bash
# Generate schedules for 2026
bundle exec rake periodic_security_control:generate_schedules[2026] RAILS_ENV=production

# Show statistics
bundle exec rake periodic_security_control:statistics[2026] RAILS_ENV=production
# Output:
# Security Control Statistics for 2026
# ========================================
# Total schedules:    156
# Pending:            52
# Generated (issue):  15
# Completed:          89
# Overdue:            0
# Skipped:            0
# Completion rate:    57.1%
```

## Permissions

| Permission | Description | Default |
|------------|-------------|---------|
| `view_psc_dashboard` | View security control dashboard | All users |
| `view_psc_schedules` | View control schedules | Members |
| `manage_psc_schedules` | Generate, skip, complete schedules | Managers |
| `manage_psc_categories` | CRUD categories and control points | Admin only |
| `configure_psc_settings` | Configure plugin settings | Admin only |

### Setting Up Permissions

1. Go to **Administration > Roles and permissions**
2. Select a role
3. Check/uncheck permissions under "Periodic Security Control"

## API Reference

### Models

#### PscControlCategory

```ruby
# Scopes
PscControlCategory.active        # Only active categories
PscControlCategory.sorted        # Ordered by position

# Methods
category.control_points_count    # Number of active control points
category.completion_rate(year)   # Completion percentage for year
```

#### PscControlPoint

```ruby
# Scopes
PscControlPoint.active           # Only active control points
PscControlPoint.by_frequency(:monthly)  # Filter by frequency

# Methods
control_point.generate_schedules_for_year(2026)
control_point.next_scheduled_date
control_point.frequency_label    # Human-readable frequency
```

#### PscSchedule

```ruby
# Scopes
PscSchedule.for_year(2026)       # Schedules for a year
PscSchedule.pending              # Pending schedules
PscSchedule.overdue              # Overdue schedules
PscSchedule.due_for_generation   # Ready for issue creation

# Methods
schedule.generate_issue!(project, author)
schedule.mark_completed!
schedule.skip!(notes)
schedule.period_label            # "January", "Q1", "Week 5"
```

### Service Class

```ruby
# Generate issues for all due schedules
result = PscScheduleGenerator.generate_due_issues
# => { generated: 5, errors: [] }

# Generate schedules for a year
result = PscScheduleGenerator.generate_year_schedules(2026)
# => { generated: 40, errors: [] }

# Get statistics
stats = PscScheduleGenerator.statistics_for_year(2026)
# => { total: 156, completed: 89, ... }
```

## Troubleshooting

### Common Issues

#### Issues not being generated automatically

1. Verify cron job is set up correctly:
   ```bash
   crontab -l | grep periodic_security_control
   ```

2. Check cron log:
   ```bash
   tail -f /path/to/redmine/log/psc_cron.log
   ```

3. Verify default project is configured:
   - Go to plugin settings
   - Ensure a project is selected

#### Migration errors

```bash
# Check migration status
bundle exec rake redmine:plugins:migrate:status RAILS_ENV=production

# Re-run migrations
bundle exec rake redmine:plugins:migrate RAILS_ENV=production
```

#### Permission denied errors

1. Ensure user has required permissions
2. Check role configuration in Administration > Roles
3. Verify project module is enabled

### Debug Mode

Enable debug logging:

```ruby
# In config/environments/production.rb
config.log_level = :debug
```

Check logs:
```bash
tail -f log/production.log | grep PSC
```

## Uninstallation

### Step 1: Rollback Migrations

```bash
bundle exec rake redmine:plugins:migrate NAME=periodic_security_control VERSION=0 RAILS_ENV=production
```

### Step 2: Remove Plugin

```bash
rm -rf plugins/periodic_security_control
```

### Step 3: Restart Redmine

```bash
touch tmp/restart.txt
```

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Development Setup

```bash
# Clone Redmine
git clone https://github.com/redmine/redmine.git
cd redmine

# Install plugin
cd plugins
git clone <your-fork-url> periodic_security_control

# Setup database
cd ..
bundle install
bundle exec rake db:create db:migrate
bundle exec rake redmine:plugins:migrate

# Run tests
bundle exec rails test plugins/periodic_security_control/test

# Start server
bundle exec rails server
```

## Changelog

### Version 1.0.0

- Initial release
- Control categories and points management
- Schedule auto-generation
- Issue integration with status sync
- Dashboard with metrics
- Calendar view
- CSV import/export
- Cron tasks for automation

## License

This plugin is released under the [MIT License](LICENSE).

```
MIT License

Copyright (c) 2026 Your Organization

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

## Support

- **Documentation**: This README
- **Issues**: [GitHub Issues](https://github.com/yourorg/periodic_security_control/issues)
- **Redmine Plugin Directory**: [redmine.org](https://www.redmine.org/plugins)

---

Made with dedication for security compliance management.
