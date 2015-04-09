use Amnesia

defdatabase Mnesia.Cache do
  deftable Map, [:key, :value], type: :set do
  end
end
