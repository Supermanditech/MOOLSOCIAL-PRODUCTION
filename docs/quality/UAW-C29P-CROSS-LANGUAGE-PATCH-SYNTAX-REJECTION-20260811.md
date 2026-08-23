# C29P cross-language patch syntax rejection

A transient patch used Dart nullable-pattern syntax in a TypeScript owner. It was removed immediately and the backend package typecheck became the required admission gate for every subsequent backend change. No invalid source was qualified or deployed.
