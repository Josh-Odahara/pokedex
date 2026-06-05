defmodule Pokedex.Repo.Migrations.CreatePokemon do
  use Ecto.Migration

  def change do
    create table(:pokemon) do
      add :number, :integer
      add :name, :string
      add :nickname, :string
      add :type, :string
      add :hp, :integer
      add :attack, :integer
      add :defense, :integer
      add :speed, :integer
      add :shiny, :boolean, default: false, null: false

      timestamps(type: :utc_datetime)
    end
  end
end
