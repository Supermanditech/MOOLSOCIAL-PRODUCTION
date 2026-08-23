# C16G Work compact-content position rejection

The first C16G focused replay found the Earn info control tappable at
320px/140% text, but its bottom initially extended 21px behind the anchored
transparent family rail. The test incorrectly treated initial position as the
same condition as scroll reachability.

The corrected proof keeps the approved navigation shell fixed and uses bounded
drags on the existing keyed Earn and Workspace scroll owners. Each target must
become wholly visible above the rail and remain hit-testable within that bound;
otherwise the ticket still rejects.
