# C32W R15 hidden action-choice navigation owner

After the known Mool Home root migration, R15 passed its machine contract and
all fourteen viewport/text-scale matrix cases. The compact operability case then
failed at the first `mool-action-<family>` minimum-target assertion inside an
`MvpActionChoiceRootV2` loop. This owner was previously hidden by the earlier
root-rail failure.

The result is preserved as 15 passed and 1 failed. No runtime source changed.
The action-choice assertions require a separately selected C32X test-only
successor before mutation.
