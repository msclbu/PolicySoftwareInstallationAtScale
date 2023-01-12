Credit to Anthony Watherston @ Microsoft https://github.com/anwather
Forked as a Proof of Concept to install applications/agents at scale in a hub spoke subscription model.

Components

Policy Definitions for Windows/Linux to only include virtual machines in compliance policy via specified tagss.
Deploy main infrastructure at Management Group level and use existing Storage Account.
Deploy runbooks and create webhooks.
Deploy Policy Assignments for both Windows and Linux at Management Group level.
Deploy Event Grid subscriptions using outputs from created Policy Assignments using Management Groups as source.