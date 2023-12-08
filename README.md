# Ruby on Rails Sync / Async (boilerplate)

## Installation

* clone this project
* `bin/setup`
* `bin/rails s`
* `bundle exec sidekiq`
* install the Frontend part to test it [Sveltekit Sync / Async (boilerplate)](https://github.com/jyclem/sveltekit-sync-async-boilerplate)

## Goals

This project has 2 main goals:

* **Suggest a way of structuring your files and folders** so that the project remains clear and maintenable no matter the size it gets.
* Allow to develop **one single endpoint** that can be used with **classic API**, **polling**, or **websocket**, reusing each time the **same authorization, sanitization and serialization mechanisms**. It means that **we develop the endpoint only once**, and then we can access to it however we want.

## Why

Concerning the first goal, structuring the code, it came from the observation that in many RoR projects, the code becomes messy as the codebase grows. The main cause is that the code is badly distributed, either being too much in the controllers, or too much in the models. I am from the ones who think that the logic should go in intermediary files such as "services" (or organizers/interactors, operations, ...), and avoid callbacks in models as much as possible (unless it is small and isolated - ie do not touch anything else than the current model). I am really enthousiastic of projects like [Interactor](https://github.com/collectiveidea/interactor) or [Trailblazer](https://github.com/trailblazer/trailblazer).
Another concern I had, was to reduce the controllers' size by separating the actions in different files, and to focus on the main goals of the controllers, which are: authorizing, sanitizing and serializing. I have never been a big fan of using dedicated gems to handle those (such as [Pundit](https://github.com/varvet/pundit) for authorization or [active_model_serializers](https://github.com/rails-api/active_model_serializers) for serialization).

About the second goal, developing one endpoint that can be accessed synchronously or asynchronously but always taking advantage of the same authorization/sanitization/serialization mechanism, the idea emerged when I realized that on several projects I worked on, we came to a point when we needed either to do some polling (for example when sending a big file or multiple files and we did not want the client to be blocked until getting the response), or to improve the user experience by using websockets. Each time we had to add a lot of code, duplicating most of the authorization/serialization mechanism, which added some complexity to the codebase, and consequently maintenance issues.

## How

At first, I thought about overriding actionpack (and more specifically the action_dispatch and route_set modules) to force the use of the new "controllers" mechanism (ie one file per action dedicated to authorization/sanitization/serialization), but it appeared to be more complicated than I expected, and I quickly concluded that it would be a mess to maintain as Rails would evolve. Also I wanted to keep all the basic Rails mechanisms if needed.
So I decided to add a few files that would allow to replace the basic mechanism only when wanted. The main file is `app/controllers/sync_async_controller.rb`, and we just need to inherit this file in a controller to trigger the magic.

The process is quite simple (you can see an example with the Todo controller):
* we define a route as usual in `config/routes.rb`
* we define a controller as usual in `app/controllers` that inherit from `SyncAsyncController`. It can be empty when using CRUD actions (index, show, create, update, destroy), and for "non-CRUD" actions we can just add empty methods with the name of the action. Instead of empty methods, it is here that we would override the default response if needed (you can have an example in app/controllers/todos_controller.rb).
* then, we create a file for each action in `app/sync_async/controllers` to set the authorization/sanitization/serialization mechanism
* and finally we create the associated actions in `app/sync_async/actions`, and the tasks in `app/sync_async/task`

### Controllers

These type of Controllers manage only the 3 following mechanisms:
* authorized?: like policies, checks if the user is authorized to call this action or not (false by default)
* sanitize: allows only the permitted parameters to be passed to the associated action
* serialize: formats the data that will be returned to the client
When a current_user is defined on the controller or channel level, we can use it in authorized? and sanitize, however, for simplicity when using asynchronousity, we cannot use it for serialize. If needed we can pass it to the action through sanitize (`params.permit(...).merge(current_user_id: current_user.id)`) and return it with the result of the action (`result.merge(current_user:)`, or `OpenStruct.new(result:, current_user:)`).

### Actions

An Action is what is directly called from a controller, it is more or less a list of all the tasks we want to process within the client query.
* it must return the object that will be serialized by the associated controller
* it must contain all the calls to the DB so that we can regroup and easily optimize the DB queries if necessary
* it must contain as many "callbacks" as possible, to lighten the models
* it can raise exception (such as HttpBadRequest, HttpNotFound, ActiveRecord::RecordInvalid, ... see app/controllers/sync_async_controller.rb for more details) to include the error in the response given to the client

### Tasks

A Task must be small and isolated, and can pretty much replace any callback that could be put in a model.
* it must not contain any call to the DB, this will be done in the action
* it must raise all the errors encountered
* it must not raise any HTTP exception, this will be handled by the action

## Why not a gem?

For now this project is experimental, but if I get some good feedbacks about it I'll create a gem. 
However, it will probably not be a gem that overrides the default Rails mechanism, but one that only adds the additional files, using for example a `bundle rails sync_async:install` and a `bundle rails sync_async:add_todo_example`. Doing so the user will still be able to custom the functioning to his needs.
