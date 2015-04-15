defmodule Cowboy.HTTP do
  defmacro __using__(_) do
    quote location: :keep do
      @behaviour :cowboy_http_handler

      def init(_type, request, _options) do
        {:ok, request, nil}
      end

      def handle(request, state) do
        {:ok, request, state}
      end

      def terminate(_reason, _request, _state) do
        :ok
      end
      
      defoverridable [init: 3, handle: 2, terminate: 3]
    end
  end
end
