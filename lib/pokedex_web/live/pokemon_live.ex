defmodule PokedexWeb.PokemonLive do
  use PokedexWeb, :live_view
  alias Pokedex.Pokedex
  alias Pokedex.CSVParser

  def mount(_params, _session, socket) do
    {:ok, socket
      |> assign(
        active_tab: :upload,
        preview_data: [],
        loading: false,
        pokemon: Pokedex.list_pokemon(),
        editing_pokemon: nil,
        search: ""
      )
      |> allow_upload(:csv, accept: ~w(.csv), max_entries: 1)
    }
  end

  def handle_event("switch_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, active_tab: String.to_atom(tab))}
  end

  def handle_event("validate", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("import_csv", _params, socket) do
    preview = consume_uploaded_entries(socket, :csv, fn %{path: path}, _entry ->
      contents = File.read!(path)
      {:ok, Pokedex.parse_csv(contents)}
    end)
    |> List.flatten()

    {:noreply, assign(socket, preview_data: preview)}
  end

  def handle_event("confirm_import", _params, socket) do
    socket = assign(socket, loading: true)
    Enum.each(socket.assigns.preview_data, fn pokemon ->
      Pokedex.create_pokemon(pokemon)
    end)

    {:noreply, assign(socket, loading: false, preview_data: [], active_tab: :browse, pokemon: Pokedex.list_pokemon())}
  end

  def handle_event("delete_pokemon", %{"id" => id}, socket) do
    id = String.to_integer(id)
    pokemon = Pokedex.get_pokemon(id)
    Pokedex.delete_pokemon(pokemon)
    {:noreply, assign(socket, pokemon: Pokedex.list_pokemon())}
  end

  def handle_event("edit_pokemon", %{"id" => id}, socket) do
    id = String.to_integer(id)
    pokemon = Pokedex.get_pokemon(id)
    {:noreply, assign(socket, editing_pokemon: pokemon)}
  end

  def handle_event("cancel_edit", _params, socket) do
    {:noreply, assign(socket, editing_pokemon: nil)}
  end

  def handle_event("update_pokemon", params, socket) do
    id = String.to_integer(params["id"])
    pokemon = Pokedex.get_pokemon(id)
    Pokedex.update_pokemon(pokemon, params)
    {:noreply, assign(socket, editing_pokemon: nil, pokemon: Pokedex.list_pokemon())}
  end

  def handle_event("search", %{"search" => search_value}, socket) do
    {:noreply, assign(socket, search: search_value)}
  end

  defp filter_pokemon(pokemon_list, ""), do: pokemon_list
  defp filter_pokemon(pokemon_list, search) do
    Enum.filter(pokemon_list, fn pokemon -> String.contains?(String.downcase(pokemon.name), String.downcase(search)) end)
  end

  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gray-900 text-white p-8">
      <div class="max-w-6xl mx-auto">
      <h1 class="text-4xl font-bold text-red-500 mb-8 max-w-6xl mx-auto text-center">Pokedex</h1>

      <div class="flex gap-4 mb-8">
        <button
          phx-click="switch_tab"
          phx-value-tab="upload"
          class={if @active_tab == :upload, do: "px-6 py-2 rounded-full font-semibold bg-red-500 text-white", else: "px-6 py-2 rounded-full font-semibold bg-gray-700 text-white hover:bg-gray-600"}>
          Upload
        </button>
        <button
          phx-click="switch_tab"
          phx-value-tab="browse"
          class={if @active_tab == :browse, do: "px-6 py-2 rounded-full font-semibold bg-red-500 text-white", else: "px-6 py-2 rounded-full font-semibold bg-gray-700 text-white hover:bg-gray-600"}>
          Browse
        </button>
      </div>

      <div :if={@active_tab == :upload}>
        <div class="bg-gray-800 rounded-lg p-8 max-w-4xl">
        <h2 class="text-xl font-semibold mb-4 text-red-400">Import Pokemon CSV</h2>
        <form phx-change="validate" phx-submit="import_csv">
          <.live_file_input upload={@uploads.csv} class="mb-4"/>
          <button type="submit" class="px-6 py-2 bg-red-500 text-white rounded-full font-semibold hover:bg-red-600">Preview CSV</button>

          <table :if={@preview_data != []} class="w-full border-collapse mt-4">
            <thead class="bg-gray-700 text-red-400">
              <tr>
                <th class="px-4 py-3 text-center">Number </th>
                <th class="px-4 py-3 text-center">Name </th>
                <th class="px-4 py-3 text-center">Nickname </th>
                <th class="px-4 py-3 text-center">Type </th>
                <th class="px-4 py-3 text-center">HP </th>
                <th class="px-4 py-3 text-center">Attack </th>
                <th class="px-4 py-3 text-center">Defense </th>
                <th class="px-4 py-3 text-center">Speed </th>
                <th class="px-4 py-3 text-center">Shiny </th>
              </tr>
            </thead>

            <tbody>
              <tr :for={pokemon <- @preview_data} class="border-b border=gray=700 text-center">
                <td><%= pokemon.number %></td>
                <td><%= pokemon.name %></td>
                <td><%= pokemon.nickname %></td>
                <td><%= pokemon.type %></td>
                <td><%= pokemon.hp %></td>
                <td><%= pokemon.attack %></td>
                <td><%= pokemon.defense %></td>
                <td><%= pokemon.speed %></td>
                <td><%= pokemon.shiny %></td>
              </tr>
            </tbody>
          </table>

          <button :if={@preview_data != []} type="button" phx-click="confirm_import" class="mt-4 px-6 py-2 bg-green-500 text-white rounded-full font-semibold hover:bg-green-600">
            Confirm Import
          </button>

          <div :if={@loading}>Loading...</div>
            </form>
          </div>

        </div>


      <div :if={@active_tab == :browse}>
        <form phx-change="search">
          <input type="search" name="search" value={@search} placeholder="Search Pokémon..." phx-change="search" class=" text-center bg-gray-800 text-white border border-gray-600 rounded-full px-4 py-2 mb-4 w-64 placeholder-gray-400 focus:outline-none focus:border-red-500" />
        </form>

      <div :if={@editing_pokemon}>
        <div class="bg-gray-800 rounded-4xl p-8">
        <h3 class="text-xl font-semibold mb-4">Editing <%= @editing_pokemon.name %></h3>
          <form phx-submit="update_pokemon">
            <label class="mt-4 mb-1 block font-semibold">Number</label>
            <input type="hidden" name="id" value={@editing_pokemon.id} class="bg-gray-700 rounded px-3 py-2 w-full grid grid-cols-2 gap-4" />
            <input type="number" name="number" value={@editing_pokemon.number} class="bg-gray-700 rounded px-3 py-2 w-full grid grid-cols-2 gap-4" />
            <label class="mt-4 mb-1 block font-semibold">Name</label>
            <input type="text" name="name" value={@editing_pokemon.name} class="bg-gray-700 rounded px-3 py-2 w-full grid grid-cols-2 gap-4" />
            <label class="mt-4 mb-1 block font-semibold">Nickname</label>
            <input type="text" name="nickname" value={@editing_pokemon.nickname} placeholder="If no Nickname, leave blank" class="bg-gray-700 rounded px-3 py-2 w-full grid grid-cols-2 gap-4" />
            <label class="mt-4 mb-1 block font-semibold">Type</label>
            <input type="text" name="type" value={@editing_pokemon.type} class="bg-gray-700 rounded px-3 py-2 w-full grid grid-cols-2 gap-4" />
            <label class="mt-4 mb-1 block font-semibold">HP</label>
            <input type="number" name="hp" value={@editing_pokemon.hp} class="bg-gray-700 rounded px-3 py-2 w-full grid grid-cols-2 gap-4" />
            <label class="mt-4 mb-1 block font-semibold">Attack</label>
            <input type="number" name="attack" value={@editing_pokemon.attack} class="bg-gray-700 rounded px-3 py-2 w-full grid grid-cols-2 gap-4" />
            <label class="mt-4 mb-1 block font-semibold">Defense</label>
            <input type="number" name="defense" value={@editing_pokemon.defense} class="bg-gray-700 rounded px-3 py-2 w-full grid grid-cols-2 gap-4" />
            <label class="mt-4 mb-1 block font-semibold">Speed</label>
            <input type="number" name="speed" value={@editing_pokemon.speed} class="bg-gray-700 rounded px-3 py-2 w-full grid grid-cols-2 gap-4" />
            <label class="mt-4 mb-1 block font-semibold">
            Shiny
            <input type="checkbox" name="shiny" checked={@editing_pokemon.shiny} class="ml-2" />
            </label>
            <button type="submit" class="px-6 py-2 mt-4 bg-green-500 text-white rounded-full font-semibold hover:bg-green-600">Save</button>
            <button type="button" phx-click="cancel_edit" class="px-6 py-2 bg-red-500 text-white rounded-full font-semibold hover:bg-red-600">Cancel</button>
        </form>
        </div>
      </div>

      <table class="w-full border-collapse mt-4">
          <thead class="border-b border-gray-700 hover:bg-gray-800">
            <tr>
              <th class="px-4 py-3 text-center">Number</th>
              <th class="px-4 py-3 text-center">Name</th>
              <th class="px-4 py-3 text-center">Nickname</th>
              <th class="px-4 py-3 text-center">Type</th>
              <th class="px-4 py-3 text-center">HP</th>
              <th class="px-4 py-3 text-center">Attack</th>
              <th class="px-4 py-3 text-center">Defense</th>
              <th class="px-4 py-3 text-center">Speed</th>
              <th class="px-4 py-3 text-center">Shiny</th>
              <th class="px-4 py-3 text-center">Actions</th>
            </tr>
          </thead>

          <tbody>
            <tr :for={pokemon <- filter_pokemon(@pokemon, @search)} class="border-b border-gray-700 hover:bg-gray-800">
              <td class="px-4 py-3 text-center"><%= pokemon.number %></td>
              <td class="px-4 py-3 text-center"><%= pokemon.name %></td>
              <td class="px-4 py-3 text-center"><%= pokemon.nickname %></td>
              <td class="px-4 py-3 text-center"><%= pokemon.type %></td>
              <td class="px-4 py-3 text-center"><%= pokemon.hp %></td>
              <td class="px-4 py-3 text-center"><%= pokemon.attack %></td>
              <td class="px-4 py-3 text-center"><%= pokemon.defense %></td>
              <td class="px-4 py-3 text-center"><%= pokemon.speed %></td>
              <td class="px-4 py-3 text-center"><%= if pokemon.shiny, do: "Yes", else: "No" %></td>
              <td class="px-4 py-3 text-center">
                <button phx-click="edit_pokemon" phx-value-id={pokemon.id} class="text-white hover:text-gray-500"> Edit</button>
                <button phx-click="delete_pokemon" phx-value-id={pokemon.id} class="text-red-500 hover:text-red-700">Delete</button>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
    </div>
  """
  end
end
