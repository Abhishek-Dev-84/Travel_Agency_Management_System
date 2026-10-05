from rest_framework.routers import DefaultRouter
from .views import DutySlipViewSet

router = DefaultRouter()
router.register(r'duty-slips', DutySlipViewSet, basename='dutyslip')

urlpatterns = router.urls
