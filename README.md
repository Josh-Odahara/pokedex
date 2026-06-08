# Pokedex

A work in progress Phoenix/LiveView CRUD application that handles Pokemon stat CSV imports, previews of the imports, confirmations and displays all imported Pokemon on another tab.

## Features
- Create, read, update and edit items
- Real-time UI updates via LiveView WebScokets
- SQLite database with Ecto
- Form Validation with Ecto
- CSV Upload, preview and review
- Tab Manager to look at your uploads
- Live search/filter on Browse page
- Duplication protection on CSV upload

## Stack
- Elixir/Phoenix
- Phoenix LiveView
- Ecto + SQLite
- Tailwind CSS

## Setup
- mix deps.get
- mix ecto.create
- mix ecto.migrate
- mix phx.server
