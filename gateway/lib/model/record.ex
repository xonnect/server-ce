defmodule Model.Record do
  defmacro fields(pairs \\ []) do
    inject_functions(pairs, __CALLER__)
  end

  def inject_functions(fields, env) do
    escaped = Macro.escape(fields)
    quotes = [
      generate_reflections(escaped),
      generate_initializers(escaped),
      generate_accessors(escaped),
      generate_updaters(escaped)
    ]
    Module.eval_quoted(env.module, quotes)
  end

  defp generate_initializers(fields) do
    defaults = for {_, value} <- fields, do: value
    initials = for {key, value} <- fields, do: replace_initializer(key, value)

    quote do
      def new(), do: new([])
      def new([]), do: {__MODULE__, unquote_splicing(defaults)}
      def new(options), do: {__MODULE__, unquote_splicing(initials)}
    end
  end

  defp replace_initializer(key, default) do
    quote do
      case :lists.keyfind(unquote(key), 1, options) do
        false -> unquote(default)
        {_, value} -> value
      end
    end
  end

  defp generate_accessors(fields) do
    for {key, _} <- fields do
      quote do
        def unquote(key)(record) do
          index = __metadata__(:index, unquote(key))
          :erlang.element(index, record)
        end

        def unquote(key)(value, record) do
          index = __metadata__(:index, unquote(key))
          :erlang.setelement(index, record, value)
        end
      end
    end
  end

  defp generate_updaters(fields) do
    values = for {key, _} <- fields, do: replace_updater(key)
    quote do
      def update([], record), do: record
      def update(options, record), do: {__MODULE__, unquote_splicing(values)}
    end
  end

  defp replace_updater(key) do
    quote do
      case :lists.keyfind(unquote(key), 1, options) do
        false -> :erlang.element(__metadata__(:index, unquote(key)), record)
        {_, value} -> value
      end
    end
  end

  defp generate_reflections(fields) do
    keys = for {key, _} <- fields, do: key
    quoted = for key <- keys do
      index = find_index(fields, key)
      quote do
        defp __metadata__(:index, unquote(key)), do: unquote(index + 2)
      end
    end

    quote do
      unquote(quoted)

      @table_name :erlang.atom_to_binary(__MODULE__, :utf8)
        |> String.split(".")
        |> List.last
        |> String.downcase
      @table_fields unquote(keys)
    end
  end

  defp find_index(kv_list, key), do: do_find_index(kv_list, key, 0)
  defp do_find_index([{key, _}|_], key, index), do: index
  defp do_find_index([], _key, _index), do: nil
  defp do_find_index([_|tail], key, index), do: do_find_index(tail, key, index + 1)
end
