# C30S registry patch expanded-JSON context rejection

Date: 2026-08-12

The first attempt to register the C30S dirty-inventory warning recurrence
assumed expanded multi-line array formatting. The durable registry uses a
compact tail, so `apply_patch` rejected the update before changing any file.

The retry used a literal tail read, retained the existing compact formatting,
added this registration with the original recurrence, and requires immediate
full JSON parsing before further work.
