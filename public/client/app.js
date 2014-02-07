// ------------ Write and expose app ------------ //

var app = angular.module("ShortlyApp", ['ngRoute']);

// --------------- Do some stuff ---------------- //

app.run(function($rootScope){
});

// ------------- Create App Routes -------------- //

app.config(function($routeProvider, $locationProvider){
  $locationProvider.html5Mode(true);
  $routeProvider
    .when('/', {
      controller: 'LinksController',
      templateUrl: "/templates/home.html"
    })
    .when('/create', {
      controller: 'ShortenController',
      templateUrl: "/templates/create.html"
    })
    .otherwise({
      redirectTo: '/'
    });  
});

// ---------- Write Controller Logic ------------ //

app.controller('LinksController', function($scope, $http){
  $http({
    method: "GET",
    url: "/links"
  })
  .then(function(data, status){
    $scope.links = data;
  })
  .catch(function(err, status){
    $console.log('err', err);
    $scope.links = 'There was an error';
  });
});

app.controller('ShortenController', function($scope, $http){
  $http({
    method: "POST",
    url: "/links"
  })
});