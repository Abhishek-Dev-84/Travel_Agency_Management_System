from rest_framework import viewsets, permissions, filters, status
from rest_framework.decorators import action
from rest_framework.response import Response
from django.db.models import Q
from .models import Invoice
from .serializers import InvoiceSerializer
from accounts.permissions import ReadOnlyOrStaffAdmin


class InvoiceViewSet(viewsets.ModelViewSet):
    queryset = Invoice.objects.select_related('booking', 'customer', 'vehicle').all()
    serializer_class = InvoiceSerializer
    permission_classes = [permissions.AllowAny]
    filter_backends = [filters.SearchFilter, filters.OrderingFilter]
    search_fields = [
        'invoice_id', 'booking__booking_id', 'customer__name',
        'customer__email', 'vehicle__make_model'
    ]
    ordering_fields = ['issue_date', 'due_date', 'grand_total', 'created_at']
    ordering = ['-created_at']

    def get_queryset(self):
        user = self.request.user
        qs = super().get_queryset()

        if user.is_authenticated and user.role == 'CUSTOMER':
            qs = qs.filter(Q(customer__user=user) | Q(customer__email__iexact=user.email))

        p_status = self.request.query_params.get('status')
        if p_status and p_status.lower() != 'all':
            qs = qs.filter(payment_status__iexact=p_status)

        customer_name = self.request.query_params.get('customer')
        if customer_name:
            qs = qs.filter(customer__name__icontains=customer_name)

        return qs

    @action(detail=False, methods=['get'], permission_classes=[permissions.AllowAny])
    def my_invoices(self, request):
        user = request.user
        customer_name = request.query_params.get('customer_name')
        qs = self.get_queryset()

        if user.is_authenticated and user.role == 'CUSTOMER':
            qs = qs.filter(Q(customer__user=user) | Q(customer__email__iexact=user.email))
        elif customer_name:
            qs = qs.filter(customer__name__icontains=customer_name.strip())

        serializer = self.get_serializer(qs, many=True)
        return Response(serializer.data)

    @action(detail=True, methods=['post'], permission_classes=[permissions.AllowAny])
    def mark_paid(self, request, pk=None):
        invoice = self.get_object()
        method = request.data.get('payment_method', 'Cash')

        invoice.payment_status = Invoice.PaymentStatus.PAID
        invoice.payment_method = method
        invoice.save()

        # Also create a paid payment record in payments app
        try:
            from payments.models import Payment
            from django.utils import timezone
            Payment.objects.create(
                invoice=invoice,
                amount=invoice.grand_total,
                payment_method=method.upper() if method.upper() in ['UPI', 'CREDIT_CARD', 'DEBIT_CARD', 'CASH'] else 'CASH',
                payment_status=Payment.PaymentStatus.PAID,
                transaction_ref=f"MANUAL-{invoice.invoice_id}",
                paid_at=timezone.now(),
                is_demo=True
            )
        except Exception:
            pass

        return Response({
            'message': f'Invoice {invoice.invoice_id} marked as Paid via {method}.',
            'invoice': InvoiceSerializer(invoice).data
        })
