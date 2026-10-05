from rest_framework.routers import DefaultRouter
from .views import WorkOrderViewSet

router = DefaultRouter()
router.register(r'maintenance', WorkOrderViewSet, basename='workorder')

urlpatterns = router.urls
