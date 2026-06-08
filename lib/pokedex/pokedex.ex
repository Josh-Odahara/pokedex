defmodule Pokedex.Pokedex do
  alias Pokedex.CSVParser
  alias Pokedex.Repo
  alias Pokedex.Pokemon

  def list_pokemon do
    Repo.all(Pokemon)
  end

  def get_pokemon(id) do
    Repo.get!(Pokemon, id)
  end

  def create_pokemon(attrs) do
    Pokemon.changeset(%Pokemon{}, attrs)
    |> Repo.insert()
  end

  def update_pokemon(pokemon, attrs) do
    Pokemon.changeset(pokemon, attrs)
    |> Repo.update()
  end

  def delete_pokemon(pokemon) do
    Repo.delete(pokemon)
  end

  def pokemon_exists?(number) do
    !!Repo.get_by(Pokemon, number: number)
  end

  def parse_csv_row([number, name, nickname, type, hp, attack, defense, speed, shiny]) do
    %{
      number: String.to_integer(number),
      name: name,
      nickname: if(nickname == "", do: nil, else: nickname),
      type: type,
      hp: String.to_integer(hp),
      defense: String.to_integer(defense),
      attack: String.to_integer(attack),
      speed: String.to_integer(speed),
      shiny: shiny |> String.downcase() |>String.to_existing_atom()
    }
  end

  def parse_csv(contents) do
    contents
    |> CSVParser.parse_string()
    |> Enum.map(fn row -> parse_csv_row(row) end)
  end

end
