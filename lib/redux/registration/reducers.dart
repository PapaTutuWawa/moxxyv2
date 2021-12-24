import "package:moxxyv2/ui/pages/register/state.dart";
import "package:moxxyv2/redux/registration/actions.dart";

RegisterPageState registerReducer(RegisterPageState state, dynamic action) {
  if (action is NewProviderAction) {
    return state.copyWith(providerIndex: action.index);
  }

  return state;
}
