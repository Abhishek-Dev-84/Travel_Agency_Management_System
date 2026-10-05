from rest_framework import viewsets, permissions, status
from rest_framework.decorators import action
from rest_framework.response import Response
from django.utils import timezone
from .models import Payment
from .serializers import PaymentSerializer, InitiatePaymentSerializer
from billing.models import Invoice


class PaymentViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = Payment.objects.select_related('invoice', 'invoice__customer').all()
    serializer_class = PaymentSerializer
    permission_classes = [permissions.AllowAny]

    @action(detail=False, methods=['post'], permission_classes=[permissions.AllowAny])
    def initiate(self, request):
        """
        Step 1: Initiate a simulated demo payment.
        Creates Payment record in PENDING status, generates demo QR and reference.
        """
        invoice_identifier = request.data.get('invoice_id')
        method = request.data.get('payment_method', 'UPI').upper()

        if not invoice_identifier:
            return Response({'error': 'Invoice ID is required.'}, status=status.HTTP_400_BAD_REQUEST)

        # Lookup invoice
        inv = None
        if str(invoice_identifier).isdigit():
            inv = Invoice.objects.filter(pk=int(invoice_identifier)).first()
        if not inv:
            inv = Invoice.objects.filter(invoice_id__iexact=str(invoice_identifier).strip()).first()

        if not inv:
            return Response({'error': 'Invoice not found.'}, status=status.HTTP_404_NOT_FOUND)

        if inv.payment_status == Invoice.PaymentStatus.PAID:
            return Response({'error': 'This invoice has already been paid.'}, status=status.HTTP_400_BAD_REQUEST)

        valid_methods = [m[0] for m in Payment.PaymentMethod.choices]
        if method not in valid_methods:
            method = 'UPI'

        payment = Payment.objects.create(
            invoice=inv,
            amount=inv.grand_total,
            payment_method=method,
            payment_status=Payment.PaymentStatus.PENDING,
            is_demo=True,
            notes='Demo simulation payment session initiated.'
        )

        return Response({
            'message': 'Demo payment session created.',
            'payment': PaymentSerializer(payment).data,
            'demo_instructions': 'This is a simulated demo payment. Confirm below to complete the transaction without real banking integration.'
        }, status=status.HTTP_201_CREATED)

    @action(detail=False, methods=['post'], permission_classes=[permissions.AllowAny])
    def confirm(self, request):
        """
        Step 2: Confirm simulated payment (Rule 9).
        Backend validates the payment and updates:
        Payment -> PAID
        Invoice -> PAID
        """
        txn_ref = request.data.get('transaction_ref')
        payment_id = request.data.get('payment_id')

        payment = None
        if txn_ref:
            payment = Payment.objects.filter(transaction_ref=txn_ref.strip()).first()
        elif payment_id:
            payment = Payment.objects.filter(payment_id=payment_id.strip()).first()

        if not payment:
            return Response({'error': 'Payment record not found.'}, status=status.HTTP_404_NOT_FOUND)

        if payment.payment_status == Payment.PaymentStatus.PAID:
            return Response({'message': 'Payment was already confirmed.', 'payment': PaymentSerializer(payment).data})

        # Update payment to PAID
        payment.payment_status = Payment.PaymentStatus.PAID
        payment.paid_at = timezone.now()
        payment.notes = 'Demo payment confirmed by user in simulation mode.'
        payment.save()

        # Update invoice to PAID (Backend authority - Rule 9)
        invoice = payment.invoice
        invoice.payment_status = Invoice.PaymentStatus.PAID
        invoice.payment_method = payment.get_payment_method_display()
        invoice.save()

        return Response({
            'message': 'Demo payment successfully verified and completed.',
            'payment': PaymentSerializer(payment).data,
            'invoice_status': invoice.payment_status
        }, status=status.HTTP_200_OK)

    @action(detail=False, methods=['post'], permission_classes=[permissions.AllowAny])
    def cancel(self, request):
        """
        Step 2 (Failure): Cancel or fail simulated payment (Rule 9).
        Payment -> FAILED / CANCELLED
        Invoice remains UNPAID
        """
        txn_ref = request.data.get('transaction_ref')
        payment_id = request.data.get('payment_id')

        payment = None
        if txn_ref:
            payment = Payment.objects.filter(transaction_ref=txn_ref.strip()).first()
        elif payment_id:
            payment = Payment.objects.filter(payment_id=payment_id.strip()).first()

        if not payment:
            return Response({'error': 'Payment record not found.'}, status=status.HTTP_404_NOT_FOUND)

        payment.payment_status = Payment.PaymentStatus.CANCELLED
        payment.notes = 'Demo payment was cancelled by user.'
        payment.save()

        return Response({
            'message': 'Payment cancelled. Invoice remains unpaid.',
            'payment': PaymentSerializer(payment).data,
            'invoice_status': payment.invoice.payment_status
        }, status=status.HTTP_200_OK)
