# Inertia Rails Template

What it does:
It add (opinionated) required gem, integrate inertia and other andd required integration for those gem. In the future I might support more customization.


- Asset Pipeline - Vite (installed with inertia rails)
- Add prompt to install sidekiq
- Add prompt to install shrine
- Add rspec
- Add simplecov

> NOTE: This is experimental rails template with inertiajs.
> Use at your own risk.

```sh
git clone git@github.com:noxasch/rails-template.git

rails _7.2.2_ new <APP_NAME> --skip-action-text --skip-active-storage --skip-hotwire --skip-jbuilder --skip-system-test --skip-bootsnap --skip-active-storage -TJA -d postgresql -m=~/PATH/TO/TEMPLATE/rails-template/template.rb
```

## References:
- [js_from_routes](https://js-from-routes.netlify.app/)
- [oj_serializers](https://github.com/ElMassimo/oj_serializers)
- [types_from_serializers](https://github.com/ElMassimo/types_from_serializers)
- [wisper](https://github.com/krisleech/wisper)
- [pagy](https://github.com/ddnexus/pagy)
- [hash_to_struct](https://github.com/a-bohush/hash_to_struct)
- [devise](https://github.com/heartcombo/devise)
- [action_policy](https://actionpolicy.evilmartians.io/#/)
- [friendly_id](https://github.com/norman/friendly_id)
- [shrine](https://shrinerb.com/docs/getting-started)
- [config](https://github.com/rubyconfig/config)
- [mutations](https://github.com/cypriss/mutations)
- [sidekiq](https://github.com/cypriss/mutations)
