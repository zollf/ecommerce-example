defmodule AppWeb.Views.Changeset do
  use AppWeb, :view

  alias AppWeb.Helpers.Errors

  def render("error.json", %{changeset: changeset}) do
    %{errors: Errors.traverse_errors(changeset)}
  end
end
