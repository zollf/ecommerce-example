defmodule App.Models do
  defmacro __using__(opts) do
    schema = App.Models.__schema__(opts)
    quote do
      alias unquote(schema), as: Schema
      alias App.Repo

      @spec all() :: [Schema.t]
      def all(), do: Repo.all(Schema)

      @spec create(map) :: {:ok, Schema.t} | {:error, Ecto.Changeset.t}
      def create(attrs) do
        %Schema{}
        |> Schema.changeset(attrs)
        |> Repo.insert()
      end

      @spec delete(map, Keyword.t) :: {:ok, Schema.t} | {:not_found, String.t}
      def delete(attrs, clauses) do
        with {:ok, entry} <- one(clauses) do
          Repo.delete entry
        end
      end

      @spec one(Keyword.t) :: {:ok, Schema.t} | {:error, Ecto.Changeset.t} | {:not_found, String.t}
      def one(clauses) do
        case Repo.get_by(Schema, clauses) do
          nil -> {:not_found, "Cannot find entry"}
          entry -> {:ok, entry}
        end
      end

      @spec update(map, Keyword.t) :: {:ok, Schema.t} | {:not_found, String.t}
      def update(attrs, clauses) do
        with {:ok, entry} <- one(clauses) do
          entry
          |> Schema.changeset(attrs)
          |> Repo.update()
        end
      end
    end
  end

  @doc """
  Gets schema from options
  """
  def __schema__(opts) do
    Keyword.get(opts, :schema)
  end
end
