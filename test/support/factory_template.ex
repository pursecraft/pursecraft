defmodule PurseCraft.FactoryTemplate do
  @moduledoc """
  Tempate module to be used by factories.

  More info about this can be found here:
    - https://www.youtube.com/watch?v=C8ycIQu2R5M
    - https://gist.github.com/idlehands/f98c35fa46e1eaecc0f55c4313d17eea

  ## Examples

      defmodule PurseCraft.ExampleFactory do
        use PurseCraft.FactoryTemplate
      end

  """

  defmacro __using__(_opts) do
    quote do
      use ExMachina.Ecto, repo: PurseCraft.Repo

      require Ecto

      def boolean, do: Enum.random([true, false])
      def integer(range \\ 0..3_000), do: Enum.random(range)
      def uuid, do: Ecto.UUID.generate()
      def uri, do: "https://" <> Faker.Internet.domain_name()
      def valid_email, do: Faker.Internet.email()
      def valid_password, do: "hello world!"

      def random_value_from_ecto_enum(schema, enum) when is_atom(schema) and is_atom(enum) do
        schema
        |> Ecto.Enum.values(enum)
        |> Enum.random()
      end

      def random_value_from_ecto_dot_enum(enum) do
        {name, _db_value} = Enum.random(enum.__enum_map__())
        name
      end

      def datetime_in_the_past(offset \\ nil, granularity \\ :second) do
        new_offset = offset || Enum.random(10..999_999_999)

        DateTime.add(DateTime.utc_now(), -new_offset, granularity)
      end

      def datetime_in_the_past_unix(offset \\ nil, granularity \\ :second) do
        DateTime.to_unix(datetime_in_the_past(offset, granularity), :microsecond)
      end
    end
  end
end
