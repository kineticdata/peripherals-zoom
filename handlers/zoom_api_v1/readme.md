# Zoom API V1
Used for requests to the Google Cloud Apps REST API Client

## Info Values
**api_key**: An api key created by a zoom app.  Instruction on creating a [api key](https://marketplace.zoom.us/docs/guides/build/jwt-app)
**api_secret**: The [api secret](https://marketplace.zoom.us/docs/guides/auth/jwt) is created at the same time as the key. 
**enable_debug_logging**: Yes or No. Controls logging behavior. 

## Parameters
**Error Handling**
  Select between returning an error message, or raising an exception.
**Method**
  HTTP Method to use for the Kinetic Core API call being made.
  Options are:
  - GET
  - POST
  - PUT
  - PATCH
  - DELETE

**Path**
  The relative API path (to the `https://api.zoom.us/v2` info value) that will be called.
  This value should begin with a forward slash `/`.  A list of [zoom](https://marketplace.zoom.us/docs/api-reference/zoom-api) API paths. 
**Body**
  The body content (JSON) that will be sent for POST, PUT, and PATCH requests.

### Example Use
  ```
    'method' => 'Get',
    'path' => '/users',
  ```

## Results
**Response Body**
  The returned value from the Rest Call (JSON format)

## Notes
