defmodule Pokedex.Pokemon do
  use Ecto.Schema
  import Ecto.Changeset

  schema "pokemon" do
    field :number, :integer
    field :name, :string
    field :nickname, :string
    field :type, :string
    field :hp, :integer
    field :attack, :integer
    field :defense, :integer
    field :speed, :integer
    field :shiny, :boolean, default: false

    timestamps(type: :utc_datetime)
  end

  def changeset(pokemon, attrs) do
    pokemon
    |> cast(attrs, [:number, :name, :nickname, :type, :hp, :attack, :defense, :speed, :shiny])
    |> validate_required([:number, :name, :type, :hp, :attack, :defense, :speed, :shiny])
  end
end
